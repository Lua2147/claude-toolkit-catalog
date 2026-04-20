#!/usr/bin/env bash
# route.sh — query the unified registry for best-match skill/agent/command/MCP/script.
# Hybrid scorer: 0.75 × cosine (nomic-embed-text via local Ollama) + 0.25 × BM25-style keyword.
# Falls back to keyword-only if vectors file is missing or Ollama is unreachable.
#
# Usage: route.sh <query> [--kind=<k>] [--source=<s>] [--tag=<t>] [--top=N]
#                        [--semantic-only] [--keyword-only]
# Env:   ROUTER_SEMANTIC_WEIGHT=0.75 (0..1, default 0.75 — tuned empirically)
#        ROUTER_DEBUG=1 — print per-stage timings to stderr
#
# Exit: 0 success / 1 registry missing / 2 empty query

set -eu
query="${1:-}"
[ -z "$query" ] && { echo "empty query" >&2; exit 2; }
shift

REG="$HOME/.claude/registry.json"
EMB="$HOME/.claude/registry-embeddings.json"
VEC="$HOME/.claude/registry-vectors.json"
[ -f "$REG" ] || { echo "registry missing at $REG — run ~/.claude/scripts/build-registry.sh" >&2; exit 1; }

kind_filter=""
source_filter=""
tag_filter=""
top=5
mode="hybrid"   # hybrid | semantic | keyword
for a in "$@"; do
  case "$a" in
    --kind=*) kind_filter="${a#--kind=}" ;;
    --source=*) source_filter="${a#--source=}" ;;
    --tag=*) tag_filter="${a#--tag=}" ;;
    --top=*) top="${a#--top=}" ;;
    --semantic-only) mode="semantic" ;;
    --keyword-only) mode="keyword" ;;
  esac
done

SEM_WEIGHT="${ROUTER_SEMANTIC_WEIGHT:-0.75}"
DEBUG="${ROUTER_DEBUG:-0}"
OLLAMA_URL="${OLLAMA_URL:-http://localhost:11434}"
EMBED_MODEL="${ROUTER_EMBED_MODEL:-nomic-embed-text}"

python3 - "$query" "$kind_filter" "$source_filter" "$tag_filter" "$top" \
                   "$REG" "$EMB" "$VEC" "$mode" "$SEM_WEIGHT" "$DEBUG" \
                   "$OLLAMA_URL" "$EMBED_MODEL" <<'PY'
import json, sys, re, os, time, math, urllib.request, urllib.error

(query, kind_f, src_f, tag_f, top,
 reg_path, emb_path, vec_path, mode, sem_weight, debug,
 ollama_url, embed_model) = sys.argv[1:14]
top = int(top)
sem_weight = max(0.0, min(1.0, float(sem_weight)))
kw_weight = 1.0 - sem_weight
debug = debug == "1"

def dlog(msg):
    if debug:
        print(f"[route.sh] {msg}", file=sys.stderr)

t_start = time.time()

# ─── Keyword layer setup ───
STOP = {
    "a","an","the","and","or","but","if","then","else","for","of","to","in","on","at",
    "by","with","from","as","is","are","was","were","be","been","being","it","its",
    "this","that","these","those","my","your","our","their","i","we","you","they","he","she",
    "do","does","did","doing","have","has","had","having","get","got","getting",
    "run","running","ran","use","using","used","make","made","go","going","went",
    "want","need","should","could","would","will","can","may","might","must",
    "how","what","why","when","where","which","who","whose","whom",
    "against","about","into","onto","over","under","between","through","during","before","after",
    "above","below","up","down","out","off","near","around","via","across",
    "some","any","all","no","not","only","own","same","so","than","too","very","just","more","most","less","least",
    "new","old","like","also","such","both","each","few","many","much","other","another"
}

q_tokens_all = re.findall(r'[a-z0-9]+', query.lower())
q_tokens = set(t for t in q_tokens_all if t not in STOP and len(t) > 1)
if not q_tokens:
    q_tokens = set(q_tokens_all)

FLOOD_FAMILIES = {"saraev","ariz","tob","hassid","rodman","gstack",
                  "pm-product-discovery","pm-product-strategy","pm-execution",
                  "pm-market-research","pm-data-analytics","pm-go-to-market",
                  "pm-marketing-growth","pm-toolkit","apollo-pack"}

def tiebreak_priority(r):
    name = r["name"].lstrip("/")
    kind = r["kind"]
    pack = name.split(":", 1)[0] if ":" in name else None
    prefix = name.split("-", 1)[0] if "-" in name else name
    kind_rank = {"mcp":0,"command":1,"agent":2,"skill":3,"script":4}.get(kind, 5)
    family_penalty = 3 if (prefix in FLOOD_FAMILIES or (pack and pack in FLOOD_FAMILIES)) else 0
    return (kind_rank + family_penalty, len(name))

reg = json.load(open(reg_path))
try:
    emb_tokens = json.load(open(emb_path))
except Exception:
    emb_tokens = {}

items = reg.get("items", [])
t_load = time.time()
dlog(f"registry_load_ms={int((t_load - t_start) * 1000)} items={len(items)}")

# ─── Semantic layer setup ───
vectors = {}
vec_meta = {}
vectors_ok = False
if mode in ("hybrid", "semantic"):
    try:
        vdata = json.load(open(vec_path))
        vectors = vdata.get("vectors", {}) or {}
        vec_meta = {k: v for k, v in vdata.items() if k != "vectors"}
        vectors_ok = bool(vectors)
    except FileNotFoundError:
        if mode == "semantic":
            print(f"error: --semantic-only requested but vectors file missing at {vec_path}", file=sys.stderr)
            sys.exit(1)
        dlog(f"vectors file missing at {vec_path} — falling back to keyword-only")
    except Exception as e:
        dlog(f"vectors file unreadable: {e} — falling back to keyword-only")

# Staleness check — warn but don't block
if vectors_ok:
    try:
        reg_mtime_now = int(os.path.getmtime(reg_path))
        reg_mtime_at_build = int(vec_meta.get("registry_mtime", 0))
        drift_days = abs(reg_mtime_now - reg_mtime_at_build) / 86400.0
        count_drift = abs(int(vec_meta.get("registry_item_count", 0)) - len(items))
        if drift_days > 7 or count_drift > 50:
            print(f"⚠️  vectors stale (drift={drift_days:.1f}d, count_delta={count_drift}) — "
                  f"run: bash ~/.claude/scripts/build-embeddings.sh", file=sys.stderr)
    except Exception:
        pass

def embed_query(text):
    body = json.dumps({"model": embed_model, "input": text}).encode("utf-8")
    req = urllib.request.Request(
        f"{ollama_url}/api/embed",
        data=body,
        headers={"Content-Type": "application/json"},
    )
    with urllib.request.urlopen(req, timeout=5) as resp:
        data = json.loads(resp.read())
    embs = data.get("embeddings") or []
    return embs[0] if embs else None

query_vec = None
if vectors_ok:
    t_embed_start = time.time()
    try:
        query_vec = embed_query(query)
    except (urllib.error.URLError, urllib.error.HTTPError, TimeoutError, ConnectionError) as e:
        if mode == "semantic":
            print(f"error: Ollama unreachable for --semantic-only: {e}", file=sys.stderr)
            sys.exit(1)
        dlog(f"Ollama unreachable ({e}) — falling back to keyword-only")
        query_vec = None
    except Exception as e:
        dlog(f"embed error ({e}) — falling back to keyword-only")
        query_vec = None
    t_embed = time.time()
    if query_vec is not None:
        dlog(f"embed_query_ms={int((t_embed - t_embed_start) * 1000)}")

use_semantic = query_vec is not None and mode in ("hybrid", "semantic")
use_keyword = mode in ("hybrid", "keyword")

# ─── Precompute query vec norm ───
qv_norm = 0.0
if use_semantic:
    qv_norm = math.sqrt(sum(x*x for x in query_vec)) or 1.0

def cosine(u):
    # cosine sim against query_vec; u already provided
    num = 0.0
    un = 0.0
    qv = query_vec
    for i in range(len(u)):
        num += u[i] * qv[i]
        un += u[i] * u[i]
    return num / ((math.sqrt(un) or 1.0) * qv_norm)

# ─── Score pass ───
t_score_start = time.time()
candidates = []  # list of dicts: id, kind, name, kw, sem
max_kw = 0.0
for item in items:
    if kind_f and item.get("kind") != kind_f: continue
    if src_f and src_f.lower() not in (item.get("source","") or "").lower(): continue
    if tag_f and tag_f.lower() not in [t.lower() for t in item.get("tags", [])]: continue

    kw_score = 0.0
    overlap_tokens = set()
    if use_keyword:
        item_tokens = set(emb_tokens.get(item["id"], []))
        if not item_tokens:
            text = f"{item.get('name','')} {item.get('description','')} {' '.join(item.get('tags',[]))}".lower()
            item_tokens = set(re.findall(r'[a-z0-9]+', text))
        item_tokens = set(t for t in item_tokens if t not in STOP and len(t) > 1)
        overlap = q_tokens & item_tokens
        if overlap:
            overlap_tokens = overlap
            kw_score = len(overlap) / max(1, len(q_tokens)) \
                       + 0.3 * len(overlap) / max(1, len(item_tokens))
            if kw_score > max_kw:
                max_kw = kw_score

    sem_score = 0.0
    if use_semantic:
        vec = vectors.get(item["id"])
        if vec:
            c = cosine(vec)
            sem_score = max(0.0, c)  # floor negative cosines to 0

    # Skip items with no signal from either layer
    if kw_score == 0.0 and sem_score == 0.0:
        continue

    candidates.append({
        "id": item["id"],
        "kind": item["kind"],
        "name": item["name"],
        "invoke_syntax": item.get("invoke_syntax",""),
        "kw_raw": kw_score,
        "sem": sem_score,
        "overlap": sorted(overlap_tokens)[:5],
    })

t_score = time.time()
dlog(f"score_pass_ms={int((t_score - t_score_start) * 1000)} candidates={len(candidates)}")

# ─── Normalize + combine ───
if mode == "keyword" or not use_semantic:
    # Pure keyword: use kw_raw
    for c in candidates:
        c["score"] = c["kw_raw"]
    method = "keyword" if mode == "keyword" else "keyword-fallback"
elif mode == "semantic":
    for c in candidates:
        c["score"] = c["sem"]
    method = "semantic-only"
else:
    # Hybrid: normalize keyword by max, combine with semantic
    if max_kw > 0:
        for c in candidates:
            kw_norm = c["kw_raw"] / max_kw
            c["score"] = sem_weight * c["sem"] + kw_weight * kw_norm
    else:
        # No keyword overlap anywhere — use semantic directly (no divide-by-zero)
        for c in candidates:
            c["score"] = c["sem"]
    method = f"hybrid(sem={sem_weight:.2f},kw={kw_weight:.2f})"

# ─── Sort + tie-break ───
candidates.sort(key=lambda r: (-r["score"], tiebreak_priority(r), r["id"]))

# Build final output
results = []
for c in candidates[:top]:
    rationale = f"overlap: {c['overlap']}" if c["overlap"] else "semantic match"
    entry = {
        "id": c["id"],
        "kind": c["kind"],
        "name": c["name"],
        "score": round(c["score"], 4),
        "semantic": round(c["sem"], 4),
        "keyword": round(c["kw_raw"], 4),
        "rationale": rationale,
        "invoke_syntax": c["invoke_syntax"],
    }
    results.append(entry)

# Ties at the top
tie_pairs = []
for i in range(len(candidates) - 1):
    if abs(candidates[i]["score"] - candidates[i+1]["score"]) < 1e-6:
        tie_pairs.append([candidates[i]["id"], candidates[i+1]["id"]])
    if len(tie_pairs) >= 5:
        break

total_ms = int((time.time() - t_start) * 1000)
dlog(f"total_ms={total_ms}")

out = {
    "query": query,
    "method": method,
    "sem_weight": sem_weight if mode == "hybrid" and use_semantic else None,
    "results": results,
    "tie_broken_pairs": tie_pairs,
}
print(json.dumps(out, indent=2))
PY

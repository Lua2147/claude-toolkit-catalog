#!/usr/bin/env bash
# route.sh — query the unified registry for best-match skill/agent/command/MCP/script
# Usage: route.sh <query> [--kind=<k>] [--source=<s>] [--tag=<t>] [--top=N]
# Exit: 0 success / 1 registry missing / 2 empty query

set -eu
query="${1:-}"
[ -z "$query" ] && { echo "empty query" >&2; exit 2; }
shift

REG="$HOME/.claude/registry.json"
EMB="$HOME/.claude/registry-embeddings.json"
[ -f "$REG" ] || { echo "registry missing at $REG — run ~/.claude/scripts/build-registry.sh" >&2; exit 1; }

kind_filter=""
source_filter=""
tag_filter=""
top=5
for a in "$@"; do
  case "$a" in
    --kind=*) kind_filter="${a#--kind=}" ;;
    --source=*) source_filter="${a#--source=}" ;;
    --tag=*) tag_filter="${a#--tag=}" ;;
    --top=*) top="${a#--top=}" ;;
  esac
done

python3 - "$query" "$kind_filter" "$source_filter" "$tag_filter" "$top" "$REG" "$EMB" <<'PY'
import json, sys, re
from collections import Counter

query, kind_f, src_f, tag_f, top, reg_path, emb_path = sys.argv[1:8]
top = int(top)

# Stop words: common English + generic verbs that flood matches without semantic value.
# Keeps domain tokens (postgres, supabase, playwright, linkedin, deal, etc.) as real signal.
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

# Tokenize query, drop stop words
q_tokens_all = re.findall(r'[a-z0-9]+', query.lower())
q_tokens = set(t for t in q_tokens_all if t not in STOP and len(t) > 1)
if not q_tokens:
    # Fall back to including stop words if the whole query was stops
    q_tokens = set(q_tokens_all)
if not q_tokens:
    print(json.dumps({"query": query, "error": "no query tokens"}))
    sys.exit(0)

# Families that flood results — demoted in tie-break, not in primary score
FLOOD_FAMILIES = {"saraev", "ariz", "tob", "hassid", "rodman", "gstack", "pm-product-discovery", "pm-product-strategy", "pm-execution", "pm-market-research", "pm-data-analytics", "pm-go-to-market", "pm-marketing-growth", "pm-toolkit", "apollo-pack"}

def tiebreak_priority(r):
    """Lower = ranks higher in tie-break. Kind-first, then family-penalty, then name length."""
    name = r["name"].lstrip("/")
    kind = r["kind"]
    # Plugin pack: "pack:skill" — check pack name
    pack = name.split(":", 1)[0] if ":" in name else None
    prefix = name.split("-", 1)[0] if "-" in name else name
    # MCPs first (most valuable + least spammy)
    kind_rank = {"mcp": 0, "command": 1, "agent": 2, "skill": 3, "script": 4}.get(kind, 5)
    # Flood families demoted
    family_penalty = 3 if (prefix in FLOOD_FAMILIES or (pack and pack in FLOOD_FAMILIES)) else 0
    return (kind_rank + family_penalty, len(name))

reg = json.load(open(reg_path))
try:
    emb = json.load(open(emb_path))
except Exception:
    emb = {}

results = []
for item in reg.get('items', []):
    if kind_f and item.get('kind') != kind_f: continue
    if src_f and src_f.lower() not in (item.get('source','') or '').lower(): continue
    if tag_f and tag_f.lower() not in [t.lower() for t in item.get('tags', [])]: continue
    # Item tokens (also stop-filtered)
    item_tokens = set(emb.get(item['id'], []))
    if not item_tokens:
        text = f"{item.get('name','')} {item.get('description','')} {' '.join(item.get('tags',[]))}".lower()
        item_tokens = set(re.findall(r'[a-z0-9]+', text))
    item_tokens = set(t for t in item_tokens if t not in STOP and len(t) > 1)
    overlap = q_tokens & item_tokens
    if not overlap: continue
    # score: (overlap/q_tokens) + 0.3*(overlap/item_tokens) — emphasizes query coverage
    score = len(overlap)/len(q_tokens) + 0.3 * len(overlap)/max(1,len(item_tokens))
    results.append({
        "id": item['id'], "kind": item['kind'], "name": item['name'],
        "score": round(score, 4),
        "rationale": f"overlap: {sorted(overlap)[:5]}",
        "invoke_syntax": item.get('invoke_syntax','')
    })

# Sort: score desc → tie-break priority (mcp>root skills>flood-family) → id asc
results.sort(key=lambda r: (-r['score'], tiebreak_priority(r), r['id']))

# detect ties
tie_pairs = []
for i in range(len(results)-1):
    if abs(results[i]['score'] - results[i+1]['score']) < 1e-6:
        tie_pairs.append([results[i]['id'], results[i+1]['id']])

out = {
    "query": query,
    "method": reg.get('embedding_method','keyword'),
    "results": results[:top],
    "tie_broken_pairs": tie_pairs[:5]
}
print(json.dumps(out, indent=2))
PY

#!/usr/bin/env bash
# build-embeddings.sh — embed every registry item via local Ollama for semantic routing.
# Output: ~/.claude/registry-vectors.json (gitignored — regenerable from registry.json).
# Model: nomic-embed-text (768-dim, Apache 2.0). Server: http://localhost:11434.
#
# Usage: bash ~/.claude/scripts/build-embeddings.sh
# Exit: 0 success / 1 ollama down / 2 model missing / 3 dim mismatch / 4 registry missing
set -eu

REG="$HOME/.claude/registry.json"
OUT="$HOME/.claude/registry-vectors.json"
MODEL="nomic-embed-text"
DIM=768
BATCH=32
SNAP="/tmp/registry-snapshot-$$.json"
OLLAMA_URL="http://localhost:11434"

[ -f "$REG" ] || { echo "registry missing at $REG — run build-registry.sh first" >&2; exit 4; }

# Probe Ollama reachability via Python (avoids RTK compression on curl)
python3 - <<PY || { echo "ollama unreachable at $OLLAMA_URL — run 'ollama serve'" >&2; exit 1; }
import urllib.request, sys
try:
    urllib.request.urlopen("$OLLAMA_URL/api/tags", timeout=2).read()
except Exception as e:
    print(f"probe failed: {e}", file=sys.stderr)
    sys.exit(1)
PY

# Snapshot registry.json so a concurrent build-registry.sh can't corrupt our read
cp "$REG" "$SNAP"
trap 'rm -f "$SNAP"' EXIT

python3 - "$SNAP" "$OUT" "$MODEL" "$DIM" "$BATCH" "$OLLAMA_URL" "$REG" <<'PY'
import json, sys, os, time, urllib.request, urllib.error
from datetime import datetime, timezone

snap, out_path, model, dim_expected, batch_size, ollama_url, reg_path = sys.argv[1:8]
dim_expected = int(dim_expected)
batch_size = int(batch_size)

reg = json.load(open(snap))
items = reg.get('items', [])
if not items:
    print("no items in registry — nothing to embed", file=sys.stderr)
    sys.exit(4)

def make_text(item):
    name = item.get('name', '')
    desc = item.get('description', '') or ''
    text = f"{name} — {desc}".strip()
    return text[:400]

def embed_batch(texts):
    """Call /api/embed with a list input. Returns list of vectors."""
    body = json.dumps({"model": model, "input": texts}).encode("utf-8")
    req = urllib.request.Request(
        f"{ollama_url}/api/embed",
        data=body,
        headers={"Content-Type": "application/json"},
    )
    try:
        with urllib.request.urlopen(req, timeout=60) as resp:
            data = json.loads(resp.read())
    except urllib.error.HTTPError as e:
        # 404 on the embed path often means model not present
        body = e.read().decode("utf-8", errors="replace")
        if e.code == 404 or "not found" in body.lower():
            print(f"model '{model}' not installed — run: ollama pull {model}", file=sys.stderr)
            sys.exit(2)
        raise
    return data.get("embeddings", [])

vectors = {}
null_ids = []
total = len(items)
n_batches = (total + batch_size - 1) // batch_size
start = time.time()

for bi in range(n_batches):
    lo = bi * batch_size
    hi = min(lo + batch_size, total)
    chunk = items[lo:hi]
    texts = [make_text(it) for it in chunk]
    try:
        vecs = embed_batch(texts)
    except Exception as e:
        print(f"[batch {bi+1}/{n_batches}] error: {e} — retrying one-by-one", file=sys.stderr)
        vecs = []
        for t in texts:
            try:
                vecs.extend(embed_batch([t]))
            except Exception as e2:
                print(f"  single-item fail: {e2}", file=sys.stderr)
                vecs.append(None)
    if len(vecs) != len(chunk):
        print(f"[batch {bi+1}] size mismatch: got {len(vecs)} vectors for {len(chunk)} items", file=sys.stderr)
        # pad with None so indices line up
        while len(vecs) < len(chunk):
            vecs.append(None)

    # Hard dim assertion on first successful vector
    if bi == 0:
        first_good = next((v for v in vecs if v), None)
        if first_good is None:
            print("first batch produced no vectors — aborting", file=sys.stderr)
            sys.exit(3)
        if len(first_good) != dim_expected:
            print(f"dim mismatch: expected {dim_expected}, got {len(first_good)} — aborting", file=sys.stderr)
            sys.exit(3)

    for it, vec in zip(chunk, vecs):
        if vec is None or len(vec) != dim_expected:
            null_ids.append(it['id'])
            continue
        vectors[it['id']] = vec

    done = hi
    elapsed = time.time() - start
    rate = done / elapsed if elapsed > 0 else 0
    eta = (total - done) / rate if rate > 0 else 0
    print(f"[batch {bi+1}/{n_batches}: {done}/{total} embedded, {rate:.1f} it/s, eta {eta:.0f}s]", flush=True)

reg_mtime = int(os.path.getmtime(reg_path))
payload = {
    "model": model,
    "built_at": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
    "dim": dim_expected,
    "count": len(vectors),
    "null_count": len(null_ids),
    "registry_item_count": total,
    "registry_mtime": reg_mtime,
    "vectors": vectors,
}

# Atomic write
tmp_out = out_path + ".tmp"
with open(tmp_out, "w") as f:
    json.dump(payload, f)
os.replace(tmp_out, out_path)

null_rate = len(null_ids) / total * 100 if total else 0
print(f"\nwrote {out_path}")
print(f"  items: {total}  embedded: {len(vectors)}  null: {len(null_ids)} ({null_rate:.2f}%)  dim: {dim_expected}")
if null_ids:
    print(f"  null sample: {null_ids[:5]}", file=sys.stderr)
PY

---
date: 2026-04-20
decision: Add semantic (embedding) scoring layer to router-hub; hybrid (cosine + BM25) on Mac, keyword-only on Achilles
affects: [mac, achilles, toolkit-repo]
reversible: yes
---

# 2026-04-20 — Phase F+G+H: Semantic routing (hybrid)

## Decision

Router-hub (`~/.claude/scripts/route.sh` → `~/.claude/skills/router-hub/scripts/route.sh`)
now runs a **hybrid scorer**: `0.75 × cosine(nomic-embed-text) + 0.25 × normalized-BM25`.
The embedding layer runs against pre-computed vectors at `~/.claude/registry-vectors.json`
(gitignored, regenerable). Ollama serves embeddings locally at `http://localhost:11434`
(no network egress).

Achilles stays **keyword-only** by design — no Ollama installed there. `route.sh` auto-detects
the missing vectors file and degrades to `keyword-fallback` method transparently.

## Rationale

Post-Phase-C audit ([router-hub-fixes](2026-04-20-router-hub-fixes.md)) went 64%→88%
via stop-word filter + kind-based tie-break. Phrased/verbose queries still failed because
BM25 can't recognize synonymy:

- "generate a financial LBO model" → `financial-analysis:lbo-model` was #5 (generic
  "generate"/"model" tokens outranked the target)
- "debug a failing Playwright test" → `/testing:test-fix` was buried (#18)
- "fix a broken browser test" → no intuitive route in top 5

Embedding-based retrieval captures semantic similarity; BM25 stays as the keyword anchor
(preserves behavior on precise queries like `investor outreach` → `mundi-orch-investor-outreach`
top-1). Hybrid gets both benefits.

Default weight 0.75/0.25 tuned empirically during build. Plan specified 0.6/0.4 as an
initial hypothesis; 0.75 materially pushed phrased-query targets into top 5 without
regressing precise-token queries. Env var `ROUTER_SEMANTIC_WEIGHT` overrides.

## Implementation

**Phase F — Embedding infrastructure (Mac only):**
- Pulled `nomic-embed-text` (274MB, 768-dim, Apache 2.0) via Ollama.
- Wrote `scripts/build-embeddings.sh`: batches 32 items per `/api/embed` request,
  snapshots `registry.json` to `/tmp/` at start (avoids torn reads during concurrent
  `build-registry.sh`), asserts dim=768 on first vector, writes atomic JSON to
  `~/.claude/registry-vectors.json` with `model`, `dim`, `count`, `registry_mtime`.
- Runtime: ~15s for 2015 items at ~130 it/s on Mac GPU.
- Added `~/.claude/.gitignore` with `registry-vectors.json` (19MB, regenerable).

**Phase G — Hybrid scorer in `route.sh`:**
- Kept inline-Python-in-bash structure (one entry point).
- Loads vectors file if present; embeds query via Ollama; falls back to keyword-only
  gracefully if file missing or Ollama unreachable.
- Normalizes BM25 by max in result set. Cosines clamped to [0,1].
- Handles `max(BM25)==0` edge case: uses semantic-only score (no divide-by-zero).
- Flags: `--semantic-only`, `--keyword-only` for diagnostics/benchmarking.
- Env vars: `ROUTER_SEMANTIC_WEIGHT`, `ROUTER_DEBUG`, `OLLAMA_URL`, `ROUTER_EMBED_MODEL`.
- Staleness detection: compares `registry.json` mtime vs stored `registry_mtime`; warns
  if drift > 7d or item-count delta > 50 but continues.

**Phase H — Sync + tests:**
- Tests at `skills/router-hub/tests/test-hybrid.sh`: 13 assertions covering 5 phrased
  queries + 2 precise regressions + 2 agent categories + 2 slash commands + 1 MCP
  category + 1 flag-behavior check. All pass.
- `build-embeddings.sh`, `route.sh`, `test-hybrid.sh`, `.gitignore` synced to Achilles.
  Vectors file stays Mac-only.
- Achilles `route.sh` verified: returns `method: keyword-fallback`, PB/CapIQ services
  still LISTEN on :8766/:8768.

## How to reverse

- `ROUTER_SEMANTIC_WEIGHT=0` — effectively keyword-only (runtime).
- `rm ~/.claude/registry-vectors.json` — next query falls back to keyword.
- `git revert <this-commit>` in catalog repo, then rsync the reverted `route.sh` to
  `~/.claude/skills/router-hub/scripts/` locally and to Achilles. Vectors file can stay;
  it won't be read by the reverted script.

## Verification

- `bash ~/.claude/scripts/build-embeddings.sh` — rebuilds vectors (~15s).
- `bash ~/.claude/skills/router-hub/tests/test-hybrid.sh` — 13/13 assertions pass.
- `ROUTER_DEBUG=1 bash ~/.claude/scripts/route.sh "any query" --top=3` — prints
  per-stage timings (embed, score, total ms).
- Achilles: `ssh achilles-mundi 'bash ~/.claude/scripts/route.sh "write an IC memo"'`
  returns `method: keyword-fallback` without warning (no vectors file is expected).
- Service health: `ssh achilles-mundi 'ss -ltn | grep -E ":8766|:8768"'` returns both.

## Cross-references

- Plan: `docs/plans/2026-04-20-toolkit-phase-fgh-semantic-routing.md`
- Predecessors:
  - [Phase A+B skill rebuild](2026-04-20-phase-ab-skill-rebuild.md)
  - [Phase C+D toolkit hardening](2026-04-20-phase-cd-toolkit-hardening.md)
  - [Router-hub discovery fixes](2026-04-20-router-hub-fixes.md)
- Memory: `project_semantic_routing.md`

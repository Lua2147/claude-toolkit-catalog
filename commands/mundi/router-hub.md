---
description: Route a natural-language request to the best-matching skill/agent/MCP via the router-hub registry
argument-hint: <natural-language task or query>
allowed-tools: Read, Bash, Task, Grep, Glob, Skill, mcp__qmd__query
---

Router-hub dispatch for: $ARGUMENTS

Invoke `Skill(skill="router-hub")` — skill lives at `~/.claude/skills/router-hub/SKILL.md`, with the wrapper `~/.claude/scripts/route.sh` as the canonical entrypoint (forwards to `skills/router-hub/scripts/route.sh`). Resolves the request against the global registry.

**Pipeline**:
1. **Registry load** — `~/.claude/registry.json` + `~/.claude/registry-embeddings.json` (refresh via `~/.claude/scripts/build-registry.sh` if stale).
2. **Match** — Gemini embedding cosine OR keyword BM25 fallback; top-5 ranked by score.
3. **Tie-break** — lexicographic on `id` when scores equal within 1e-6.
4. **Output** — JSON to stdout: `{query, method, results: [{id, kind, name, score, rationale, invoke_syntax}], tie_broken_pairs}`.
5. **Filters (optional)** — pass through `--kind skill|agent|command|mcp`, `--source`, `--tag`.
6. **Execute-top (optional)** — if user passes `--execute-top`, invoke the #1 match via its `invoke_syntax` and return the result.

**Agent surface (alternative)**: `Task(subagent_type="router-hub", prompt="<natural-language task>")` — returns dispatch plan. Agent definition at `~/.claude/agents/router-hub.md`.

**Expected outputs**:
- Structured JSON match list (schema above)
- If `--execute-top`, the chosen tool's output appended
- On miss: message "no router match — falling back to toolkit-scout" and hand off to `Skill(skill="toolkit-scout")`

**Skills/agents referenced**: `router-hub` (Wave 2B, forward-ref), `toolkit-scout`, `mwp` (I/O contract pattern).

**Note**: router-hub shipped 2026-04-19; discovery quality improved 2026-04-20 with stop-word filter + kind-based tie-break (audit relevance 64% → 88%). See `tmp/claude-toolkit-catalog/decisions/2026-04-20-router-hub-fixes.md`.

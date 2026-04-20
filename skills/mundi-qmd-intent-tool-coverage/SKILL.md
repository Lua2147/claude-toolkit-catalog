---
name: mundi-qmd-intent-tool-coverage
description: Audit MCP intent → tool coverage — cross-reference MCP tool catalogs against intent buckets to find gaps (intents with zero tools, tools unclaimed by any intent, consuming-app data needs not wired). Applies to PitchBook, CapIQ, and any future MCPs. Use when onboarding a new MCP, adding new intents, or investigating "why doesn't my query route to anything."
allowed-tools: Read, Write, Edit, Bash, Grep, Glob
---

# Mundi QMD — Intent ↔ Tool Coverage Audit

## Overview

MCPs expose tools. Orchestrators route on intents (semantic buckets). The two have to stay in sync or queries miss. This runbook audits coverage: which intents have no tools, which tools have no intent, which consuming-app needs are unfulfilled.

Already exists in mature form for PitchBook + CapIQ; this skill codifies the pattern so future MCPs get the same treatment.

## When to use

- **Onboarding a new MCP** — audit coverage before wiring into orchestrators
- **Adding new intent buckets** — verify each has ≥1 tool
- **Investigating routing misses** — "/mundi:origination-run returned nothing" may trace to intent-gap
- **Pre-release eval harness** — pass@k must cover every documented intent
- **Periodic (quarterly) drift check** — catalogs drift as tools get added without intent updates

## Three coverage dimensions

```
1. Intent → Tool         → every intent has ≥1 tool
2. Tool → Intent          → every tool is claimed by ≥1 intent bucket
3. Consuming-App → Tool   → every app data need maps to a tool that exists
```

## The existing implementations (source material)

### PitchBook
- `apps/pitchbook-mcp/src/catalog.py` — INTENT_INDEX (47 intents)
- `apps/pitchbook-mcp/data/tool_catalog.json` — auto-generated from `@pb_tool` decorators (224 tools)
- `apps/pitchbook-mcp/src/catalog.py` — INTENT_INDEX Python dict (canonical — not a separate JSON file); exposed at `pitchbook://catalog` MCP resource
- `apps/pitchbook-mcp/tests/eval/test_routing.py` — pass@k evaluation harness
- Coverage dashboard resource: `pitchbook://catalog`

### CapIQ
- `apps/capiq-mcp/src/catalog.py` — INTENT_INDEX (12 intents)
- `apps/capiq-mcp/data/capiq_intent_index.json`
- `apps/capiq-mcp/data/capiq_consuming_app_mapping.json` — 7 apps, 26 data needs, **12 MISSING tool gaps** (still real)
- `apps/capiq-mcp/scripts/verify_phase_3.py` — phase-3 coverage check script

## The audit runbook (apply to any MCP)

```
[1] Tool census
    grep -c '@pb_tool(mcp)\|@capiq_tool(mcp)\|@mcp.tool()' src/tools/*.py
    rebuild tool_catalog.json (scripts/rebuild_tool_catalog.py pattern)

[2] Intent census
    cat src/catalog.py | extract INTENT_INDEX keys

[3] Intent → tool coverage
    for each intent: intent_index[intent] must be non-empty
    fail → intent with zero tools → add tools OR remove intent

[4] Tool → intent coverage
    flatten all intent_index values → unique tool set
    diff against tool_catalog tool set → orphans have no intent

[5] Consuming-app needs
    cat data/<mcp>_consuming_app_mapping.json
    for each app need: tool referenced must exist in catalog
    gaps → add tool OR update app's data need

[6] Pass@k eval
    run tests/eval/test_routing.py with k=1,3,5
    fail if pass@3 < 0.85 for top-priority intents
```

## Invocation

Typical — run the verify script per MCP:
```bash
cd apps/pitchbook-mcp && python scripts/verify_phase_3.py
cd apps/capiq-mcp && python scripts/verify_phase_3.py
```

Or inline skill call for ad-hoc audit:
```python
Skill(skill="mundi-qmd-intent-tool-coverage", {
  mcp_path: "apps/pitchbook-mcp",
  check: "all"  # or "intent_to_tool" / "consuming_app"
})
```

## I/O contract (MWP)

**state_reads:**
- `apps/<mcp>/src/catalog.py` — INTENT_INDEX
- `apps/<mcp>/data/tool_catalog.json` — full tool spec
- `apps/<mcp>/data/<mcp>_consuming_app_mapping.json` — app needs
- `apps/<mcp>/tests/eval/test_routing.py` — eval harness

**state_writes:**
- `apps/<mcp>/docs/coverage-audit-<date>.md` — report with:
  - Intents with zero tools
  - Tools with no intent claim
  - Consuming-app gaps
  - Pass@k scores
  - Recommended patches

## Output format

```markdown
# <MCP> Coverage Audit — <date>

## Summary
- Tools: 224
- Intents: 47
- Apps consuming: 7
- Orphan tools: 3
- Zero-tool intents: 0
- Consuming-app gaps: 12 (CapIQ) / 0 (PB)
- Pass@3: 0.91 (PB) / 0.78 (CapIQ — below threshold)

## Gaps
1. Intent `exit-readiness` has only 1 tool — add `pb_fund_exits_due`?
2. Tool `pb_xyz` orphan — add to intent `due-diligence`?
3. Consuming-app `capiq-mcp/tools/counterparty-list-building` needs `decision_maker_history` — no such tool.

## Recommendations
...
```

## Failure modes

| failure | recovery |
|---|---|
| `tool_catalog.json` stale (tools added, catalog not rebuilt) | run `scripts/rebuild_tool_catalog.py` first |
| Intent index schema drift (new field added without migration) | schema-version check before audit |
| Pass@k fails because eval harness has stale fixtures | regenerate fixtures; don't suppress the failure |

## Cross-references

- **Implementations:** `apps/pitchbook-mcp/src/catalog.py`, `apps/capiq-mcp/src/catalog.py`, both `tests/eval/test_routing.py`
- **Memory:** `reference_pitchbook_lessons_for_capiq.md` (17 lessons including schema registry + review cascade)
- **Related skills:** `mundi-orch-multi-llm-route` (task→provider classifier — different problem, similar audit pattern)
- **KB:** `docs/knowledge-base/outputs/qmd-action-items-for-wave2.md` item #4

## Safety

- **Don't publish a coverage audit without rerunning tool_catalog rebuild first.** Stale catalogs produce false "orphans."
- Coverage percentages are a signal, not a verdict — a 0-tool intent might be intentional (future-work placeholder).
- Pass@k on a small test set lies — require ≥30 queries per intent bucket for meaningful scores.

---
date: 2026-04-20
decision: Reconcile pitchbook-mcp + capiq-mcp CLAUDE.md headers against codebase ground truth
affects: [monorepo, memory]
reversible: yes (via git revert in monorepo)
---

# App CLAUDE.md contradictions fixed

## Decision

Rewrote the headers of `apps/pitchbook-mcp/CLAUDE.md` and `apps/capiq-mcp/CLAUDE.md` to match verified ground truth from the actual codebases. Both files previously claimed contradictory or outdated version/tool/test counts.

### pitchbook-mcp

| claim | source | reality |
|---|---|---|
| "v2.1.1 — 108 tools, 1,603 tests" (strikethrough) + "v2.2.2" | prior header | Header contradicted itself |
| "211 tools · 3,070 tests" | prior body | Stale |
| **v2.2.2** | `pyproject.toml` version= | ✅ Confirmed |
| **224 tools** | `grep -c '@pb_tool(mcp)' src/tools/*.py` | ✅ New header uses 224 |
| **4,053 tests** | `pytest --collect-only -q` | ✅ New header uses 4,053 |

Rewrote the header block (lines 1-9). Version-history table at line ~1186 preserves the v2.1.1 / v2.0.1 historical entries unchanged — those are correct as history.

### capiq-mcp

| claim | source | reality |
|---|---|---|
| "78 MCP tools (76 data + 2 management)" | prior header | Undercount |
| "545 tests" | prior header body | ✅ Correct |
| "21 tools, 94 tests" | `memory/project_capiq_mcp.md` frontmatter | Stale (2026-03-24 initial merge snapshot) |
| **81 tools** | `grep -rhE "@(capiq_tool\(mcp\)\|mcp\.tool\(\))" src/ \| wc -l` | ✅ New header uses 81 |
| **545 tests** | `pytest --collect-only` | ✅ Confirmed |
| **v0.1.0** | `pyproject.toml` version= | ✅ Confirmed |

Rewrote the header block (lines 1-11). Also updated `memory/project_capiq_mcp.md` frontmatter from "21 tools, 94 tests" to "81 tools, 545 tests (as of 2026-04-20)" with an inline note explaining the prior 21/94 was from initial merge.

## Rationale

Both apps have been growing since initial merge. Their CLAUDE.md headers drifted. When an audit subagent reads them, contradictory claims get flagged — wasting token budget and forcing disambiguation every time. Single source of truth: code + pyproject + pytest collection, documented in the headers.

## Verification

```bash
# pitchbook ground truth
cd apps/pitchbook-mcp
grep -E "^version" pyproject.toml                         # → version = "2.2.2"
grep -c '@pb_tool(mcp)' src/tools/*.py | awk -F: '{s+=$2} END {print s}'   # → 224
python3 -m pytest --collect-only -q --no-header 2>&1 | tail -1             # → 4,053 tests collected

# capiq ground truth
cd apps/capiq-mcp
grep -E "^version" pyproject.toml                         # → version = "0.1.0"
grep -rhE "@(capiq_tool\(mcp\)|mcp\.tool\(\))" src/ | wc -l  # → 81
CAPIQ_PACE_ENABLED=0 python3 -m pytest --collect-only -q --no-header 2>&1 | tail -1  # → 545 tests collected

# Header now matches
head -11 apps/pitchbook-mcp/CLAUDE.md
head -11 apps/capiq-mcp/CLAUDE.md
```

## How to reverse

```bash
cd "/Users/mundiprinceps/Mundi Princeps"
git log --oneline apps/pitchbook-mcp/CLAUDE.md apps/capiq-mcp/CLAUDE.md | head -3
# git checkout <sha>~1 -- apps/pitchbook-mcp/CLAUDE.md apps/capiq-mcp/CLAUDE.md
```

Memory revert:
```bash
# The prior memory frontmatter is preserved in git blame of MEMORY.md and project_capiq_mcp.md;
# copy-paste it back from history if the updated counts turn out wrong.
```

## Related

- Monorepo commit `497af72f`: `docs(app-claude-md): fix pitchbook + capiq contradictions` on `Lua2147/Mundi-Princeps` main.
- Wiki `1.4-mcp-servers.md` inspection (also flagged by audit) — false positive: the lines 8,11 showing Explorium are in the historical tweet-ingestion table, and the current MCP inventory below already has Explorium strikethrough-Legacy-boxed per `docs/knowledge-base/CLAUDE.md` rule "never raw-delete retired refs, box them".
- Wiki `lead-gen-reference.md:42,68` — already strikethrough + rationale.
- Wiki `token-optimization.md:145,148` — already strikethrough.

---
date: 2026-04-20
decision: Trim global ~/.claude/CLAUDE.md — remove claude-mem auto-block, Legacy MCP boxout, slash-command enumeration, stale aggregate counts
affects: [mac, achilles, memory]
reversible: yes (git history of toolkit-catalog + memory backup)
---

# Global CLAUDE.md trim

## Decision

Cut `~/.claude/CLAUDE.md` from **130 lines + 32-line auto-block (162 total injected per session) → 80 lines**. ~50% reduction in always-loaded global context.

Synced identical file to Achilles `/home/mundi/.claude/CLAUDE.md`.

## What was removed

| lines (old) | content | why removed | replacement |
|---|---|---|---|
| 1-33 | `<claude-mem-context>` auto-block (20 observation rows) | claude-mem plugin disabled 2026-04-20; won't regenerate | N/A — plugin disabled |
| 82-86 | Legacy/Removed MCPs boxout (4 retired servers, full rationale) | Historical content, not operational guidance | 1-line pointer to `docs/knowledge-base/outputs/phase-2-mcp-audit-report.md` |
| 104-112 | Full `/mundi:*` command enumeration (20+ commands named inline) | Duplicated `wiki/00-workflows/INDEX.md` | 1-line pointer to `wiki/00-workflows/INDEX.md` |
| 123 | 400-char aggregate-counts line ("528 skills, 173 agents, 29 /mundi, 24+ MCPs, 201 scripts, 15 rule files, + CLI tools…") | Counts stale within days | Pointer to `memory/state.md` where live counts live |

## What was added/corrected

- **pitchbook**: 211 → 224 tools (reflecting v2.2.2 fix from `2026-04-20-app-claude-md-contradictions.md`)
- **capiq**: added as MCP entry (81 tools, v0.1.0 on Achilles) — was missing from the global table entirely
- **context-mode**: table row now notes "plugin disabled 2026-04-20; tools still reachable via ToolSearch"
- **router-hub pointer**: Workflow Rules section now points to `bash ~/.claude/scripts/route.sh` as the pre-build discovery step
- **toolkit-catalog decisions pointer**: Related Docs section now references `tmp/claude-toolkit-catalog/decisions/` for dated plugin/MCP decisions
- **KB section**: updated with `wiki/00-indexes/INDEX.md` + `outputs/INDEX.md` pointers (created 2026-04-20 in KB indexing commit `fe169c51`)

## Rationale

Global CLAUDE.md is injected into every session. Every line is a token cost paid across every conversation for weeks. Three rules applied:

1. **If the plugin is off, its auto-block goes.** The claude-mem `<claude-mem-context>` block was always-on per-session context for a plugin we disabled today. Auto-regen won't happen with the plugin off, so we can delete the injected text safely.
2. **History belongs in outputs/, not in global CLAUDE.md.** The Legacy-MCP boxout was 5 lines of "why X was removed" — useful once when the removals happened, burden every session thereafter. Pointer to the audit report preserves the reasoning for anyone who needs it.
3. **Duplicate = delete.** The `/mundi:*` enumeration duplicated `wiki/00-workflows/INDEX.md`. Stale counts line duplicated `state.md` (which is updated more reliably). Pointers beat embedded copies.

## Verification

```bash
wc -l ~/.claude/CLAUDE.md
# → 80 lines (was 130 + 32 auto-block = 162)

ssh achilles-mundi 'wc -l /home/mundi/.claude/CLAUDE.md'
# → 80 lines

# claude-mem block absent
grep -c "claude-mem-context" ~/.claude/CLAUDE.md
# → 0

# All retired MCPs + historical content moved to pointers
grep -cE "unusualwhales|explorium|capiq orphan" ~/.claude/CLAUDE.md
# → 0 (history lives in phase-2-mcp-audit-report.md now)

# Pointers work
ls -la docs/knowledge-base/outputs/phase-2-mcp-audit-report.md     # exists
ls -la docs/knowledge-base/wiki/00-workflows/INDEX.md              # exists
ls -la ~/.claude/projects/-Users-mundiprinceps-Mundi-Princeps/memory/state.md  # exists
```

## How to reverse

```bash
cd "/Users/mundiprinceps/Mundi Princeps/tmp/claude-toolkit-catalog"
git log --oneline decisions/ | head -5
# the prior CLAUDE.md content lives in git blame of ~/.claude/CLAUDE.md (not tracked in any repo)
```

If you want the old file back: the backup is at `~/.claude/settings.json.bak-clademem-*` (same session, adjacent change). No separate CLAUDE.md backup — the old content is effectively lost from the home dir, but the *structural diff* is preserved in this decisions file above.

If you actually need to recover specific lines (e.g., "that paragraph about X was useful"), `git log -p --follow ~/.claude/projects/*/sessions/` in the Claude transcript dir may have the old file captured in a tool result.

## Related

- Companion decisions: claude-mem disable (`2026-04-20-claude-mem-disabled.md`) — prerequisite for removing the auto-block.
- Memory cross-ref: `~/.claude/projects/-Users-mundiprinceps-Mundi-Princeps/memory/state.md` — the target for "operational state" that moved out of CLAUDE.md.
- KB master index: `docs/knowledge-base/INDEX.md` — refreshed in same-day commit `fe169c51`.

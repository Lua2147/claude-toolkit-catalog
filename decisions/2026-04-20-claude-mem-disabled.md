---
date: 2026-04-20
decision: Disable claude-mem@thedotmack plugin on Mac + Achilles; keep all data preserved
affects: [mac, achilles, settings.json, memory]
reversible: yes (data intact)
---

# claude-mem plugin disabled

## Decision

Set `enabledPlugins["claude-mem@thedotmack"]: false` in:
- Mac: `~/.claude/settings.json`
- Achilles: `/home/mundi/.claude/settings.json`

All data preserved — plugin cache, observation database, vector embeddings, and logs remain untouched on both machines. Disable is one-command reversible.

## Rationale

The plugin was injecting a 20-row `<claude-mem-context>` "Recent Activity" table into every session (via SessionStart hooks running `context-generator.cjs`). The injected observations were ranked "relevant" but in practice surfaced stale entries (Feb 2026 config-review rows appearing in April work sessions) — i.e., the ranker's relevance signal wasn't sharp enough to beat its noise floor.

**Overlap with qmd MCP made claude-mem redundant.**

- `qmd` provides FTS5 + vector search over ~6,000 session-transcript docs in `~/.claude/projects/*/*.md`, invoked explicitly via `mcp__qmd__*` tools when needed.
- `claude-mem` provided automatic session-start injection of 20 observations via hooks.
- On-demand beats auto-inject when the model can match query intent. Auto-inject pays context cost every session whether relevant or not.

Additional cost claude-mem imposed:
- SessionStart hook × 3 (smart-install, bun-runner worker start, context hook) on every `startup|clear|compact` event.
- Persistent Node worker process (`worker-service.cjs`, 1.8 MB) running in background.
- ~2-3 KB of context per session dedicated to the auto-block.

## Data preserved

**Mac `~/.claude-mem/` (1.4 GB total):**
- `claude-mem.db` — 224 MB SQLite: all observations, projects, timeline, tags
- `chroma/` — 763 MB vector embeddings
- `logs/` — 394 MB hook + worker logs
- `observer-sessions/` — empty
- `settings.json` — 1.5 KB plugin config

**Achilles `/home/mundi/.claude-mem/` (78 MB)** — equivalent structure, smaller corpus.

Plugin cache at `~/.claude/plugins/cache/thedotmack/claude-mem/` also untouched (v10.5.2 + v9.0.12 both present).

## How to reverse

```bash
# Mac
jq '.enabledPlugins["claude-mem@thedotmack"] = true' ~/.claude/settings.json > /tmp/s.json && mv /tmp/s.json ~/.claude/settings.json

# Achilles
ssh achilles-mundi 'jq ".enabledPlugins[\"claude-mem@thedotmack\"] = true" /home/mundi/.claude/settings.json > /tmp/s.json && mv /tmp/s.json /home/mundi/.claude/settings.json'
```

Re-enable picks up at the exact observation-DB state preserved. No reindex needed.

## Per-session explicit use (while plugin disabled)

The claude-mem MCP server (`mcp-search`) is still registered; tools are reachable via ToolSearch:

```
ToolSearch query: "select:mcp__plugin_claude-mem_mcp-search__search,mcp__plugin_claude-mem_mcp-search__get_observations"
```

But prefer `qmd` for session-transcript search — it's the more general tool and already covers the workflow.

## Verification

```bash
jq '.enabledPlugins["claude-mem@thedotmack"]' ~/.claude/settings.json
# → false

ssh achilles-mundi 'jq ".enabledPlugins[\"claude-mem@thedotmack\"]" /home/mundi/.claude/settings.json'
# → false

# Data still present
du -sh ~/.claude-mem                         # ~1.4G
ssh achilles-mundi 'du -sh /home/mundi/.claude-mem'  # ~78M
```

## Related

- Backup files: `~/.claude/settings.json.bak-clademem-*` (Mac), `/home/mundi/.claude/settings.json.bak-claudemem-*` (Achilles).
- Memory: `~/.claude/projects/-Users-mundiprinceps-Mundi-Princeps/memory/feedback_claude_mem_disabled.md`.
- Companion decisions this session: context-mode disable (2026-04-20-context-mode-disabled.md) + dialogue-gate removal (2026-04-20-dialogue-gate-removed.md). Pattern: disable plugins whose hooks inject per-session prompt overhead when their value is covered by on-demand alternatives.

---
date: 2026-04-20
decision: Disable context-mode@context-mode plugin in settings.json on Mac + Achilles
affects: [mac, achilles, settings.json, memory]
reversible: yes
---

# Context-mode plugin disabled

## Decision

Set `enabledPlugins["context-mode@context-mode"]: false` in:
- Mac: `~/.claude/settings.json`
- Achilles: `/home/mundi/.claude/settings.json`

Plugin files remain installed on disk. MCP tools (`mcp__plugin_context-mode_context-mode__ctx_*`) remain discoverable via ToolSearch — they just aren't auto-loaded into every session.

## Rationale

Context-mode registers 6 session hooks (`pretooluse`, `posttooluse`, `sessionstart`, `userpromptsubmit`, `precompact`, `routing-block`) that:

1. Inject a `context_window_protection` directive at every session start (~2 KB prompt overhead).
2. Add "use `ctx_*` tools instead of Bash" tips on every `PreToolUse:Bash` and `PreToolUse:Read`.
3. Force-route large tool outputs through a SQLite sandbox via the PostToolUse hook.

On the Achilles `investor-outbound` tmux session, repeated `ctx_execute` errors and pipeline stalls were observed in mid/late April 2026. The hook overhead + friction exceeded the sandbox benefit for the kinds of tool outputs this user typically generates (mostly <50 KB — well under the threshold where sandbox value kicks in).

The plugin's own `configSchema` only exposes `enabled: true/false` — no per-hook disable, no threshold config. So "disable" is the only available knob.

## How to reverse

If a future task genuinely needs the sandbox (e.g., ingesting 500 KB of logs, or 50+ URL fetches with indexed search):

**Temporary per-task use (recommended):** invoke MCP tools explicitly via ToolSearch without re-enabling the plugin hooks:
```
ToolSearch query: "select:mcp__plugin_context-mode_context-mode__ctx_batch_execute,mcp__plugin_context-mode_context-mode__ctx_search"
```

**Full re-enable (only if per-session tips + posttool routing are wanted):**
```bash
# Mac
jq '.enabledPlugins["context-mode@context-mode"] = true' ~/.claude/settings.json > /tmp/s.json && mv /tmp/s.json ~/.claude/settings.json
# Achilles
ssh achilles-mundi 'jq ".enabledPlugins[\"context-mode@context-mode\"] = true" /home/mundi/.claude/settings.json > /tmp/s.json && mv /tmp/s.json /home/mundi/.claude/settings.json'
```

Hooks will load on next session start.

## Verification

```bash
jq '.enabledPlugins["context-mode@context-mode"]' ~/.claude/settings.json
# → false
ssh achilles-mundi 'jq ".enabledPlugins[\"context-mode@context-mode\"]" /home/mundi/.claude/settings.json'
# → false
```

Also cross-referenced in memory at:
`~/.claude/projects/-Users-mundiprinceps-Mundi-Princeps/memory/feedback_context_mode_disabled.md`

## Related

- Backup files: `~/.claude/settings.json.bak-contextmode-1776662693` (Mac), `/home/mundi/.claude/settings.json.bak-contextmode-*` (Achilles).
- Hook files still on disk at `~/.claude/plugins/cache/context-mode/context-mode/1.0.89/hooks/` (6 `.mjs` files + `hooks.json`). Not invoked while plugin disabled.

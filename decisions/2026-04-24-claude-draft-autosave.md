# 2026-04-24 — claude-draft-autosave

## Context

Louis typed a long Phase 4 brainstorm prompt in a Claude Code TUI session (the `intent-rec` Ghostty tab, session jsonl `b9f6cbda-4d30-403a-88c7-446793835cfd.jsonl`), attempted to copy it to clipboard, only captured a fragment, then deleted the input buffer before realizing. The full prompt was unrecoverable:

- Claude Code's TUI input box is in-memory only. Unsubmitted text is never written to the session jsonl.
- Ghostty's scrollback captures terminal output, not TUI widget contents (the input box area is redrawn in place via cursor positioning).
- Ghostty's on-disk cache (`~/Library/Caches/com.mitchellh.ghostty/Cache.db`) is HTTP URL caching only — no scrollback persistence.
- No clipboard history manager was installed on the Mac (only FreeFlow, which is a cursor tool).

## Decision

Ship two scripts to the toolkit catalog + install as auto-running services on both `mundis-mac-mini` and `achilles`:

- `scripts/claude-draft-autosave.sh` — every 30 seconds, enumerate every tmux pane whose foreground command is `claude` / `claude.exe`, `tmux capture-pane -p -S -500` on it, and append to `~/.claude-drafts/<host>__<session>__w<win>__p<pane>.log`. Dedupes by sha1 of captured content so unchanged frames don't bloat the log. Caps each log at 10 MB with tail truncation.
- `scripts/claude-draft-find.sh "<fragment>"` — grep drafts with surrounding context; supports `--since 2h` / `--context 40`.

## Why tmux capture-pane works where Ghostty scrollback doesn't

Claude Code's TUI uses in-place redraws via ANSI cursor positioning — the input box occupies fixed lines at the bottom of the terminal. Ghostty's own scrollback only retains content that's scrolled OFF the visible screen; the input box never scrolls, so its contents never enter Ghostty's scrollback buffer.

tmux, however, runs *inside* the terminal as a multiplexer and owns its own virtual terminal per pane. `tmux capture-pane -p -S -500` snapshots the pane's *current visible buffer plus 500 lines of scrollback*. Because Claude Code's input box IS visible, its current rendered state is captured. A 30-second snapshot cadence catches most drafts before the user deletes them (even fast typists pause longer than that).

Panes running Claude Code directly in Ghostty (no tmux) are NOT covered. Users who want coverage must either:
1. Run `claude` inside `tmux new-session -A -s <name>`, or
2. Accept the blind spot for non-tmux panes.

On the Mac mini, 8 of 11 Claude sessions are in tmux. On Achilles, 14 of 14 are in tmux.

## Install

| Host | Service | Path | Cadence |
|------|---------|------|---------|
| `mundis-mac-mini` | `com.mundi.claude-draft-autosave` launchd | `~/Library/LaunchAgents/com.mundi.claude-draft-autosave.plist` | 30s |
| `achilles` | `claude-draft-autosave.timer` systemd user | `~/.config/systemd/user/claude-draft-autosave.{service,timer}` | 30s |

Achilles requires `loginctl enable-linger mundi` (already set) so the user timer survives SSH disconnect.

Draft directory: `~/.claude-drafts/` on both hosts.

## Recovery usage

```bash
# On whichever host the lost session was running:
bash ~/bin/claude-draft-find.sh "fragment of what you typed"

# Narrow to recent:
bash ~/bin/claude-draft-find.sh "fragment" --since 2h --context 40
```

Grep returns every snapshot that contained the fragment, with 20 lines of context by default (adjust with `--context N`).

## Known limitations

- **Non-tmux Ghostty tabs**: not captured. On the Mac mini there are 3 such tabs (ttys001/007/009 running `claude` directly under Ghostty). Could be covered in a v2 via macOS accessibility API polling the focused Ghostty surface's text — but adds TCC permission asks and AppleScript complexity. Deferred.
- **Typing faster than 30s between states**: in rare cases a user could draft + delete + redraft in <30s and the middle state is lost. Could be mitigated by shortening the interval to 10s at cost of more log noise. 30s chosen as a sane default.
- **Disk usage**: ~10 MB cap per pane × N panes. On a host with 14 panes = ~140 MB ceiling. Negligible.
- **No encryption at rest**: `~/.claude-drafts/` is mode-0755 for the dir, 0644 for logs. Same as your existing shell history — don't put secrets there. Acceptable tradeoff for a recovery tool.

## Follow-ups (not shipped)

- Ghostty-native coverage for non-tmux tabs (macOS accessibility API).
- Integration with the existing toolkit-scout skill so "find my lost prompt" becomes a `/mundi:` slash command.
- Pruning job — currently logs grow to 10 MB per pane then tail-truncate; could add a weekly full-archive + reset.

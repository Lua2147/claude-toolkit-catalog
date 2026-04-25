# 2026-04-24 — clipboard-history

## Context

Paired with `claude-draft-autosave.sh` (same day). That tool captures tmux panes running Claude. Gaps it doesn't cover:

- Non-tmux Ghostty tabs on the Mac where Claude Code runs directly.
- Cases where text was on the system clipboard and then overwritten by the next `pbcopy` before the user could paste it (today's Phase 4 prompt was lost this way — Louis copied a fragment, deleted the TUI buffer expecting the full text was captured, discovered the clipboard only held a fragment).

## Decision

Ship a polling clipboard history daemon on both hosts:

- `scripts/clipboard-history.sh` — polls `pbpaste` on Mac (every 2s) / `xclip`/`wl-paste` on Linux + dumps all `tmux list-buffers` buffer contents. Dedup'd by sha1. Appends to `~/.clipboard-history/clipboard.log` with timestamp, source tag (`clipboard` or `tmux:<buffer>`), byte count, sha1. 50 MB cap with tail-truncate rotation.
- `scripts/clipboard-history-find.sh "<fragment>"` — grep the log with context. `--since 2h` and `--context N` flags.

## Coverage topology

| Copy origin | Captured by |
|---|---|
| Mac Ghostty native selection / Cmd-C in GUI apps | Mac `pbpaste` daemon |
| Mac tmux yank (OSC52 via `set -g set-clipboard on`) | Mac `pbpaste` daemon (text arrives via Ghostty's OSC52 forwarding) |
| Mac tmux yank that DIDN'T fire OSC52 (setting off, terminal incompatible) | Mac daemon's `tmux list-buffers` poll |
| Achilles tmux yank via SSH'd Ghostty (OSC52 forwarded to Mac) | Mac `pbpaste` daemon |
| Achilles tmux yank when OSC52 fails or Ghostty session dies mid-yank | Achilles daemon's `tmux list-buffers` poll |
| Achilles X11 clipboard (Xvfb for VNC'd Chrome) | Achilles `xclip` — works if X selection populated during the VNC session |

Both hosts' tmux configs already have `set -g set-clipboard on` (confirmed during install), so the primary flow is Achilles yank → OSC52 → Ghostty → Mac clipboard → Mac daemon. The Achilles-side daemon is redundant insurance.

## Install

| Host | Service | Cadence | File |
|------|---------|---------|------|
| `mundis-mac-mini` | `com.mundi.clipboard-history` launchd | 2s poll, KeepAlive | `~/Library/LaunchAgents/com.mundi.clipboard-history.plist` |
| `achilles` | `clipboard-history.service` systemd user (simple/Restart=always) | 2s poll | `~/.config/systemd/user/clipboard-history.service` |

Achilles requires `loginctl enable-linger mundi` (already set from the draft-autosave install).

## Recovery usage

```bash
# Mac
bash /Users/mundiprinceps/Mundi\ Princeps/tmp/claude-toolkit-catalog/scripts/clipboard-history-find.sh "fragment"

# Achilles
ssh achilles-mundi 'bash ~/bin/clipboard-history-find.sh "fragment"'

# Narrow to recent — supports h/m/d suffixes
bash clipboard-history-find.sh "fragment" --since 2h --context 40
```

## Security / privacy notes

- Log file is mode 0644 (same as your shell history). **Do NOT copy passwords/secrets to clipboard** — they will land in this log plaintext and the log is not encrypted. Rotate the log (`: > ~/.clipboard-history/clipboard.log`) after copying anything sensitive.
- No remote exfiltration. Log stays on local disk.
- 50 MB per-host cap auto-rotates via tail-truncate; no cron needed.
- The daemons don't inspect or filter content — everything on the clipboard gets written. If you want hostname / path / class filters, add them in a follow-up.

## Install dependencies

None beyond what's on both hosts:
- Mac: `pbpaste` (built-in), `shasum` (built-in), `tmux` (homebrew, already installed)
- Achilles: `tmux` (installed). `xclip`/`wl-paste` optional — daemon degrades to tmux-buffer-only if missing. Headless Linux + SSH-only sessions have no X clipboard anyway, so tmux buffer capture is the meaningful path on Achilles.

## Follow-ups (not shipped)

- Clipboard-history pruning daemon (weekly full-dump + reset) — not urgent with 50 MB cap.
- Filter list for common secret patterns (API key shapes, `BEGIN PRIVATE KEY`, etc.) so accidentally-copied secrets get redacted at daemon level rather than relying on user hygiene.
- Integration with draft-autosave so recovery tooling has a single `/mundi:recover-lost-text "fragment"` command that searches both corpora.

#!/usr/bin/env bash
# claude-draft-autosave.sh — snapshot every tmux pane that's running `claude`
# so typed-but-unsubmitted prompts survive accidental Ctrl-C / Cmd-K / tab-close.
#
# How it works:
#   Every invocation walks all tmux panes. For each pane whose foreground
#   command is claude (or claude.exe), capture the visible scrollback into
#   ~/.claude-drafts/<host>__<session>__<win>__<pane>.log, appending only
#   new lines (dedup against the previous snapshot). Rolling log capped at
#   ~10 MB per pane via truncation when a threshold is hit.
#
# Why:
#   Claude Code's TUI input buffer is in-memory only. If you type a long
#   prompt and hit Ctrl-C or Cmd-K before submit, it's gone — jsonl doesn't
#   record drafts, Ghostty scrollback doesn't capture TUI widgets. But the
#   TUI does render the typed text on-screen between keystrokes, which
#   tmux's visible buffer CAN capture if we snapshot often enough.
#
# Usage:
#   bash claude-draft-autosave.sh               # one pass, exit
#   bash claude-draft-autosave.sh --loop 30     # re-run forever, 30s interval
#
# Install as a service:
#   Mac:       ~/Library/LaunchAgents/com.mundi.claude-draft-autosave.plist
#   Linux:     ~/.config/systemd/user/claude-draft-autosave.{service,timer}
#
# Recovery:
#   bash claude-draft-find.sh "fragment of what you lost"

set -eu

INTERVAL=""
if [ "${1:-}" = "--loop" ]; then
    INTERVAL="${2:-30}"
fi

HOST="$(hostname -s 2>/dev/null || hostname)"
DRAFT_DIR="${CLAUDE_DRAFT_DIR:-$HOME/.claude-drafts}"
MAX_BYTES="${CLAUDE_DRAFT_MAX_BYTES:-10485760}"  # 10 MB cap per pane

# Locate a tmux binary — handle non-standard Homebrew paths used on mac mini.
TMUX_BIN="${TMUX_BIN_OVERRIDE:-}"
if [ -z "$TMUX_BIN" ]; then
    for candidate in \
        /Users/mundiprinceps/.homebrew/bin/tmux \
        /opt/homebrew/bin/tmux \
        /usr/local/bin/tmux \
        /usr/bin/tmux \
        /home/mundi/.homebrew/bin/tmux; do
        if [ -x "$candidate" ]; then TMUX_BIN="$candidate"; break; fi
    done
fi
[ -z "$TMUX_BIN" ] && TMUX_BIN="$(command -v tmux 2>/dev/null || true)"
[ -z "$TMUX_BIN" ] && { echo "claude-draft-autosave: no tmux found" >&2; exit 1; }

mkdir -p "$DRAFT_DIR"

snapshot_once() {
    # tmux may not have a server up — that's fine, nothing to capture.
    "$TMUX_BIN" list-panes -a -F '#{session_name}|#{window_index}|#{pane_index}|#{pane_id}|#{pane_current_command}' 2>/dev/null | \
    while IFS='|' read -r sess win pane pane_id cmd; do
        case "$cmd" in
            claude|claude.exe|node) : ;;
            *) continue ;;
        esac

        # Sanitize names for filenames.
        safe_sess=$(printf '%s' "$sess" | tr -c 'A-Za-z0-9._-' '_')
        logfile="$DRAFT_DIR/${HOST}__${safe_sess}__w${win}__p${pane}.log"
        marker="$DRAFT_DIR/.${HOST}__${safe_sess}__w${win}__p${pane}.last"

        # Capture the currently visible + last 500 lines of scrollback.
        captured=$("$TMUX_BIN" capture-pane -t "$pane_id" -p -S -500 2>/dev/null || true)
        [ -z "$captured" ] && continue

        # Hash for dedup — avoid blowing log size with unchanged frames.
        new_hash=$(printf '%s' "$captured" | /usr/bin/shasum | awk '{print $1}')
        old_hash=$(cat "$marker" 2>/dev/null || true)
        [ "$new_hash" = "$old_hash" ] && continue

        # Append with a header line.
        {
            printf '\n===== %s | %s:%s.%s | %s =====\n' \
                "$(date '+%Y-%m-%dT%H:%M:%S%z')" "$sess" "$win" "$pane" "$cmd"
            printf '%s\n' "$captured"
        } >> "$logfile"

        printf '%s' "$new_hash" > "$marker"

        # Rotate when the file crosses the cap (keep tail only).
        if [ -f "$logfile" ]; then
            bytes=$(wc -c < "$logfile" | tr -d ' ')
            if [ "$bytes" -gt "$MAX_BYTES" ]; then
                tail -c "$((MAX_BYTES / 2))" "$logfile" > "$logfile.tmp" && mv "$logfile.tmp" "$logfile"
            fi
        fi
    done
}

if [ -n "$INTERVAL" ]; then
    while true; do
        snapshot_once
        sleep "$INTERVAL"
    done
else
    snapshot_once
fi

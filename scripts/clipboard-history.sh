#!/usr/bin/env bash
# clipboard-history.sh — capture every distinct clipboard value on this host
# so nothing you copy is ever lost to the next Cmd-C.
#
# On macOS: polls `pbpaste` every 2 seconds, writes each new value to
# ~/.clipboard-history/clipboard.log with timestamp, dedup'd by sha1.
#
# On Linux (Achilles): polls `xclip`/`wl-paste` if available. Also dumps
# tmux paste buffers (`tmux list-buffers`) — that catches yanks from
# tmux's copy-mode even when the terminal doesn't forward OSC52.
#
# Coverage model: on the Mac, EVERY clipboard write from any source
# (Ghostty native, Mac tmux, or Achilles tmux via Ghostty's OSC52
# forwarding with `set-clipboard on`) ends up on the Mac pasteboard
# and is captured here. Achilles-side tmux buffer polling is a belt-
# and-suspenders backup in case OSC52 forwarding is ever disabled
# or the terminal doesn't support it.
#
# Usage:
#   bash clipboard-history.sh               # one pass, exit (Linux also dumps tmux buffers)
#   bash clipboard-history.sh --loop 2      # poll every 2s forever (recommended)
#
# Recovery: `bash clipboard-history-find.sh "fragment"`

set -eu

INTERVAL=""
if [ "${1:-}" = "--loop" ]; then
    INTERVAL="${2:-2}"
fi

HIST_DIR="${CLIPBOARD_HIST_DIR:-$HOME/.clipboard-history}"
LOG="$HIST_DIR/clipboard.log"
MARKER="$HIST_DIR/.last.sha1"
MAX_BYTES="${CLIPBOARD_HIST_MAX_BYTES:-52428800}"   # 50 MB cap
mkdir -p "$HIST_DIR"

# Detect platform + pick clipboard reader.
OS="$(uname -s)"
READER=""
case "$OS" in
    Darwin)
        READER="pbpaste"
        ;;
    Linux)
        if command -v wl-paste >/dev/null 2>&1; then
            READER="wl-paste --no-newline"
        elif command -v xclip >/dev/null 2>&1; then
            READER="xclip -selection clipboard -o"
        elif command -v xsel >/dev/null 2>&1; then
            READER="xsel --clipboard --output"
        fi
        ;;
esac

# Locate tmux for buffer fallback (mainly useful on Achilles).
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

log_entry() {
    local source="$1"
    local content="$2"
    [ -z "$content" ] && return 0

    local hash
    hash=$(printf '%s' "$content" | /usr/bin/shasum | awk '{print $1}')
    local prev=""
    if [ -f "$MARKER.$source" ]; then
        prev=$(cat "$MARKER.$source" 2>/dev/null || true)
    fi
    [ "$hash" = "$prev" ] && return 0
    printf '%s' "$hash" > "$MARKER.$source"

    {
        printf '\n===== %s | source=%s | %d bytes | sha1=%s =====\n' \
            "$(date '+%Y-%m-%dT%H:%M:%S%z')" "$source" "${#content}" "$hash"
        printf '%s\n' "$content"
    } >> "$LOG"

    # Rotate if log grows past cap.
    if [ -f "$LOG" ]; then
        bytes=$(wc -c < "$LOG" | tr -d ' ')
        if [ "$bytes" -gt "$MAX_BYTES" ]; then
            tail -c "$((MAX_BYTES / 2))" "$LOG" > "$LOG.tmp" && mv "$LOG.tmp" "$LOG"
        fi
    fi
}

poll_once() {
    # System clipboard poll.
    if [ -n "$READER" ]; then
        content="$(eval "$READER" 2>/dev/null || true)"
        [ -n "$content" ] && log_entry "clipboard" "$content"
    fi

    # tmux paste buffers — enumerate all, log each distinct one.
    if [ -n "$TMUX_BIN" ]; then
        "$TMUX_BIN" list-buffers -F '#{buffer_name}' 2>/dev/null | while read -r bname; do
            [ -z "$bname" ] && continue
            bcontent="$("$TMUX_BIN" show-buffer -b "$bname" 2>/dev/null || true)"
            [ -z "$bcontent" ] && continue
            log_entry "tmux:$bname" "$bcontent"
        done
    fi
}

if [ -n "$INTERVAL" ]; then
    while true; do
        poll_once
        sleep "$INTERVAL"
    done
else
    poll_once
fi

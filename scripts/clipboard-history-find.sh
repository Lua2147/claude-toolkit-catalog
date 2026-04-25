#!/usr/bin/env bash
# clipboard-history-find.sh — grep the clipboard history log for a fragment
# of something you remember copying. Shows timestamped matches with context.
#
# Usage:
#   bash clipboard-history-find.sh "fragment you copied"
#   bash clipboard-history-find.sh "fragment" --since 2h
#   bash clipboard-history-find.sh "fragment" --context 40

set -eu

QUERY="${1:-}"
[ -z "$QUERY" ] && { echo "usage: $0 <query> [--since DURATION] [--context N]" >&2; exit 2; }
shift

SINCE=""
CTX="10"
while [ $# -gt 0 ]; do
    case "$1" in
        --since)   SINCE="$2"; shift 2 ;;
        --context) CTX="$2";   shift 2 ;;
        *)         shift ;;
    esac
done

HIST_DIR="${CLIPBOARD_HIST_DIR:-$HOME/.clipboard-history}"
LOG="$HIST_DIR/clipboard.log"
[ -f "$LOG" ] || { echo "no history log at $LOG" >&2; exit 3; }

# If --since given, tail the log to only recent lines.
if [ -n "$SINCE" ]; then
    # Crude time filter — find line-range for timestamps within window.
    case "$SINCE" in
        *h) mins=$((${SINCE%h} * 60)) ;;
        *m) mins="${SINCE%m}" ;;
        *d) mins=$((${SINCE%d} * 1440)) ;;
        *)  mins="$SINCE" ;;
    esac
    cutoff_epoch=$(($(date +%s) - mins * 60))
    # Walk entries (each block starts with "===== <iso-ts> |")
    python3 - "$LOG" "$QUERY" "$cutoff_epoch" "$CTX" <<'PY'
import sys, re, datetime
log, q, cutoff, ctx = sys.argv[1], sys.argv[2], int(sys.argv[3]), int(sys.argv[4])
with open(log, encoding='utf-8', errors='replace') as f:
    blocks = []
    current = []
    cur_ts = None
    for line in f:
        m = re.match(r'^===== (\S+) \|', line)
        if m:
            if current:
                blocks.append((cur_ts, ''.join(current)))
            current = [line]
            try:
                cur_ts = int(datetime.datetime.fromisoformat(m.group(1)).timestamp())
            except Exception:
                cur_ts = None
        else:
            current.append(line)
    if current:
        blocks.append((cur_ts, ''.join(current)))
hits = 0
for ts, block in blocks:
    if ts is None or ts < cutoff:
        continue
    if q in block:
        hits += 1
        print(block)
if hits == 0:
    print(f"No hits for: {q} (within --since window)", file=sys.stderr)
    sys.exit(1)
PY
else
    # Whole log
    if grep -q -F -- "$QUERY" "$LOG"; then
        grep -n -F -B "$CTX" -A "$CTX" -- "$QUERY" "$LOG"
    else
        echo "No hits for: $QUERY" >&2
        exit 1
    fi
fi

#!/usr/bin/env bash
# claude-draft-find.sh — search drafts captured by claude-draft-autosave.sh
# for a fragment of a lost prompt. Prints hits with surrounding context.
#
# Usage:
#   bash claude-draft-find.sh "the text you remember typing"
#   bash claude-draft-find.sh "fragment" --since 2h    # only recent drafts
#   bash claude-draft-find.sh "fragment" --context 40  # lines of surrounding context

set -eu

QUERY="${1:-}"
[ -z "$QUERY" ] && { echo "usage: $0 <query> [--since DURATION] [--context N]" >&2; exit 2; }
shift

SINCE=""
CTX="20"
while [ $# -gt 0 ]; do
    case "$1" in
        --since) SINCE="$2"; shift 2 ;;
        --context) CTX="$2"; shift 2 ;;
        *) shift ;;
    esac
done

DRAFT_DIR="${CLAUDE_DRAFT_DIR:-$HOME/.claude-drafts}"
[ -d "$DRAFT_DIR" ] || { echo "no drafts at $DRAFT_DIR" >&2; exit 3; }

FIND_ARGS=()
if [ -n "$SINCE" ]; then
    # macOS BSD find supports -newermt; Linux find also.
    case "$SINCE" in
        *h) mins=$((${SINCE%h} * 60)); FIND_ARGS=(-mmin "-$mins") ;;
        *m) FIND_ARGS=(-mmin "-${SINCE%m}") ;;
        *d) FIND_ARGS=(-mtime "-${SINCE%d}") ;;
        *)  FIND_ARGS=(-mmin "-$SINCE") ;;  # bare number = minutes
    esac
fi

# List matching logs (newest first), grep each for the fragment with context.
matched=0
while IFS= read -r logfile; do
    if grep -q -F -- "$QUERY" "$logfile" 2>/dev/null; then
        matched=$((matched + 1))
        printf '\n========== %s ==========\n' "$logfile"
        grep -n -F -B "$CTX" -A "$CTX" -- "$QUERY" "$logfile" || true
    fi
done < <(find "$DRAFT_DIR" -maxdepth 1 -type f -name '*.log' "${FIND_ARGS[@]}" 2>/dev/null | xargs -I {} ls -t {} 2>/dev/null || true)

if [ "$matched" -eq 0 ]; then
    echo "No hits for: $QUERY"
    echo "Tip: try a shorter fragment or remove --since to widen the window."
    exit 1
fi

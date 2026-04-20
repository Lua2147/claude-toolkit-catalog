---
date: 2026-04-20
decision: Remove dialogue-gate hooks from settings.json on Mac + Achilles
affects: [mac, achilles, settings.json, memory]
reversible: yes
---

# Dialogue-gate hooks removed

## Decision

Stripped two hook entries from `~/.claude/settings.json` (Mac) and `/home/mundi/.claude/settings.json` (Achilles):
- `PreToolUse` on `Bash` → `bash ~/.claude/hooks/dialogue-gate.sh`
- `PostToolUse` on `Bash` → `bash ~/.claude/hooks/dialogue-gate-post.sh`

The `.sh` files themselves remain on disk (`~/.claude/hooks/dialogue-gate.sh`, `~/.claude/hooks/dialogue-gate-post.sh`) — only their registration in settings.json was removed. Also cleared any stale lock at `/tmp/claude-dialogue-gate.lock` on both machines.

## What it did

The two hooks implemented a forced stop-after-commit workflow gate:

1. **Post-hook** (`dialogue-gate-post.sh`) watched every `Bash` tool use; if the command contained `git commit`, it wrote `/tmp/claude-dialogue-gate.lock` with the commit message and printed a "STOP HERE. Wait for user" directive.
2. **Pre-hook** (`dialogue-gate.sh`) checked for that lock file on every subsequent `Bash` call and hard-blocked with `exit 1` until the user said "continue" / "next" and the lock was removed.

The effect: after any commit, every further Bash command was rejected until explicit user approval.

## Rationale

The gate is an opinionated workflow enforcer — disciplined, but high friction. User decision (2026-04-20): prefer agent to continue freely after commits rather than stop for per-commit approval. The gate was interrupting legitimate follow-up work (push, status check, continuing a multi-step task that happened to include a commit).

## How to reverse

Re-add the two hook entries to `settings.json` on both machines. The `.sh` files are still on disk, so no reinstall needed:

```bash
# Mac
jq '.hooks.PreToolUse += [{"matcher": "Bash", "hooks": [{"type": "command", "command": "bash /Users/mundiprinceps/.claude/hooks/dialogue-gate.sh"}]}] |
    .hooks.PostToolUse += [{"matcher": "Bash", "hooks": [{"type": "command", "command": "bash /Users/mundiprinceps/.claude/hooks/dialogue-gate-post.sh"}]}]' \
    ~/.claude/settings.json > /tmp/s.json && mv /tmp/s.json ~/.claude/settings.json

# Achilles — same jq with /home/mundi paths
```

## Verification

```bash
jq '[.hooks.PreToolUse, .hooks.PostToolUse] | [.. | .command? // empty] | map(select(test("dialogue-gate"))) | length' ~/.claude/settings.json
# → 0

ssh achilles-mundi 'jq "[.hooks.PreToolUse, .hooks.PostToolUse] | [.. | .command? // empty] | map(select(test(\"dialogue-gate\"))) | length" /home/mundi/.claude/settings.json'
# → 0
```

Cross-referenced in memory at:
`~/.claude/projects/-Users-mundiprinceps-Mundi-Princeps/memory/feedback_dialogue_gate_removed.md`

## Related

- Backup files: `~/.claude/settings.json.bak-dialoguegate-*` (Mac) and same pattern on Achilles.
- Hook files preserved: `~/.claude/hooks/dialogue-gate.sh`, `~/.claude/hooks/dialogue-gate-post.sh`.

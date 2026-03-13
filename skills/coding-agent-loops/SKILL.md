---
name: coding-agent-loops
description: Run long-lived AI coding agents in persistent tmux sessions with retry loops and completion hooks. Use when running multi-step coding tasks, GSD phases, or any programming agent that needs to survive restarts, retry on failure, and notify on completion.
---

# Coding Agent Loops

Run AI coding agents in persistent, self-healing sessions with automatic retry and completion notification.

## Core Concept

Instead of one long agent session that stalls or dies, run many short sessions in a loop. Each iteration starts fresh — no accumulated context. The agent picks up where it left off via files and git history.

## Quick Start with Claude Code

### Single Task
```bash
tmux new -d -s my-task \
  "cd ~/Mundi\ Princeps && claude --dangerously-skip-permissions -p 'Fix the authentication bug in apps/kadenwood'; \
   EXIT_CODE=\$?; echo EXITED: \$EXIT_CODE; sleep 999999"
```

### GSD Phase Execution
```bash
tmux new -d -s gsd-phase \
  "cd ~/Mundi\ Princeps && claude --dangerously-skip-permissions -p '/gsd:execute-phase'; \
   EXIT_CODE=\$?; echo EXITED: \$EXIT_CODE; sleep 999999"
```

### Parallel Agents (different worktrees)
```bash
# Agent 1: KPI reconciliation
tmux new -d -s kpi-work \
  "cd ~/Mundi\ Princeps/apps/kadenwood/.worktrees/kpi-reconciliation && \
   claude --dangerously-skip-permissions -p 'Complete KPI reconciliation per SESSION_BRIEF.md'; \
   echo DONE; sleep 999999"

# Agent 2: UI overhaul
tmux new -d -s ui-work \
  "cd ~/Mundi\ Princeps/apps/kadenwood/.worktrees/ui-overhaul && \
   claude --dangerously-skip-permissions -p 'Complete UI overhaul per SESSION_BRIEF.md'; \
   echo DONE; sleep 999999"
```

## Session Management

```bash
# List active sessions
tmux list-sessions

# Check progress
tmux capture-pane -t my-task -p | tail -20

# Attach to watch
tmux attach -t my-task

# Kill a session
tmux kill-session -t my-task
```

## Retry Loop Pattern

For tasks that may fail or need multiple iterations:

```bash
tmux new -d -s resilient-task \
  "cd ~/Mundi\ Princeps && \
   for i in 1 2 3 4 5; do \
     echo '=== Iteration \$i ==='; \
     claude --dangerously-skip-permissions -p 'Continue work on [TASK]. Check git log and status for prior progress.'; \
     if [ \$? -eq 0 ]; then echo 'SUCCESS on iteration \$i'; break; fi; \
     echo 'Failed, retrying...'; sleep 5; \
   done; \
   echo FINAL_EXIT: \$?; sleep 999999"
```

## When to Use What

| Scenario | Approach |
|----------|----------|
| Multi-step feature | tmux + Claude Code with GSD |
| Parallel independent tasks | Separate tmux sessions per worktree |
| Task that keeps stalling | Retry loop with iteration limit |
| Quick one-off fix | Direct `claude -p` (no tmux needed) |
| Long migration/refactor | tmux + GSD execute-phase |

## Tips

- **Always use `--dangerously-skip-permissions`** for unattended sessions
- **Use worktrees** (`/worktree` command) for parallel work on same repo
- **Check git log** after completion — did the agent actually commit?
- **Keep `sleep 999999`** at the end so you can read the output
- **Use `-p` flag** for non-interactive prompt mode

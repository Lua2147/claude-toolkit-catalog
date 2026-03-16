---
name: agentic-orchestration-patterns
description: Context forking, parallel sessions, agent escalation/handoff, session state persistence, and hook lifecycle patterns for multi-agent Claude architectures. Maps to CCA Domain 1 (27%).
---

# Agentic Orchestration Patterns

## Overview

Patterns for designing multi-agent systems with Claude: forking context across parallel sessions, managing escalation and handoff between agents, persisting state across sessions, and leveraging the full hook lifecycle for automation.

## Context Forking and Parallel Sessions

### When to Fork

Fork context when tasks are independent and can run concurrently. Each fork gets a subset of the original context relevant to its task.

```python
# Pattern: Fan-out with task-specific context
tasks = [
    {"role": "security-reviewer", "context": security_files, "prompt": "Audit for vulnerabilities"},
    {"role": "test-writer", "context": source_files, "prompt": "Generate missing unit tests"},
    {"role": "doc-writer", "context": api_files, "prompt": "Update API documentation"},
]
# Run all three as parallel subagents, merge results
```

### Fork Boundaries

- Each fork should have a single, well-defined objective
- Pass only the files and context each fork needs (minimize shared state)
- Define the expected output format before forking
- Set a timeout — a hung fork blocks the merge

## Agent Escalation and Handoff

### Escalation Protocol

```
L0: Autonomous (agent resolves without human input)
L1: Flag-and-continue (agent flags uncertainty, continues with best guess)
L2: Block-and-ask (agent stops, requests human decision)
L3: Abort (agent detects a safety/compliance issue, halts immediately)
```

### Handoff Pattern

When transferring work between agents, pass a structured handoff object:

```json
{
  "task_id": "refactor-auth-module",
  "status": "partial",
  "completed": ["extracted interfaces", "wrote tests for UserService"],
  "remaining": ["migrate legacy handlers", "update integration tests"],
  "decisions_made": ["kept bcrypt over argon2 for backward compat"],
  "blockers": ["needs DB migration approval before handler migration"],
  "files_modified": ["src/auth/interfaces.ts", "src/auth/user-service.ts"],
  "files_to_read": ["src/auth/legacy-handlers.ts"]
}
```

## Session State Persistence

### Scratchpad Files

Use `.claude/state/` or project-level scratchpad files to persist state across `/compact` and session restarts.

```bash
# Write progress to a scratchpad
echo '{"phase": 2, "completed_files": ["a.ts", "b.ts"], "next": "c.ts"}' > .claude/state/migration-progress.json

# Read it back after /compact
cat .claude/state/migration-progress.json
```

### What to Persist

- Current phase and progress counters
- Decisions made (so they are not re-debated)
- File lists already processed
- Error patterns encountered (avoid repeating failed approaches)

### What NOT to Persist

- Full file contents (re-read from disk)
- Conversation history (use `/compact` summaries)
- Temporary debug output

## Hook Lifecycle Reference

| Hook | Fires When | Use Cases |
|------|-----------|-----------|
| `PreToolUse` | Before any tool call executes | Token compression (RTK), input validation, command rewriting |
| `PostToolUse` | After a tool call returns | Auto-formatting, linting, logging, metrics |
| `Notification` | When Claude sends a notification | Desktop alerts, Slack integration, progress tracking |
| `Stop` | When Claude finishes a response | Checklist enforcement, memory writes, session logging |
| `SessionStart` | When a new session begins | Context loading, update checks, environment validation |
| `SubagentStop` | When a subagent completes | Result aggregation, quality checks on subagent output |

### Hook Configuration

```json
{
  "hooks": {
    "PreToolUse": [
      { "matcher": "Bash", "command": "rtk rewrite $INPUT" }
    ],
    "PostToolUse": [
      { "matcher": "Write|Edit", "command": "prettier --write $FILE" }
    ],
    "Stop": [
      { "command": "echo 'Did you update memory?' >&2" }
    ]
  }
}
```

## When to Use

- Building autonomous agent pipelines (e.g., research -> analyze -> report)
- Coordinating multiple Claude Code sessions on a large refactor
- Ensuring session continuity across context window limits
- Automating pre/post processing of tool calls

## Common Mistakes

1. **Over-forking**: Creating too many parallel agents when sequential processing is simpler and more reliable
2. **Missing handoff state**: Agents lose context during handoff because the handoff object was incomplete
3. **Hook side effects**: Hooks that modify files can interfere with Claude's expectations of file state — keep hooks idempotent
4. **No escalation path**: Agents loop on errors instead of escalating to human review
5. **Persisting stale state**: Scratchpad files from previous sessions mislead the current session — timestamp and validate before trusting

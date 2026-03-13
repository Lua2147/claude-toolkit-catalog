---
name: cron-guide
description: Schedule recurring tasks, one-shot actions, and automated workflows using OpenClaw's built-in cron system. Use when setting up heartbeats, scheduled reports, tweet scheduling, email checks, or any timed automation.
---

# Cron Guide — Scheduled Automation

OpenClaw has a built-in cron system for scheduling tasks. No external cron, no crontab — everything runs through the `cron` tool.

## Schedule Types

### One-Shot (run once at a specific time)
```json
{
  "schedule": {"kind": "at", "at": "2026-03-10T15:00:00Z"}
}
```

### Recurring Interval
```json
{
  "schedule": {"kind": "every", "everyMs": 3600000}
}
```
Common intervals: 900000 (15min), 3600000 (1hr), 86400000 (24hr)

### Cron Expression
```json
{
  "schedule": {"kind": "cron", "expr": "0 8 * * *", "tz": "America/Chicago"}
}
```

## Job Types

### System Event (main session)
Injects a message into your current session — Felix sees it and acts:
```json
{
  "name": "hourly-inbox-check",
  "schedule": {"kind": "every", "everyMs": 3600000},
  "sessionTarget": "main",
  "payload": {
    "kind": "systemEvent",
    "text": "Check inbox for new emails. Triage and respond to anything urgent."
  },
  "enabled": true
}
```

### Agent Turn (isolated session)
Spawns a fresh agent session to handle the task independently:
```json
{
  "name": "nightly-revenue-review",
  "schedule": {"kind": "cron", "expr": "0 3 * * *", "tz": "America/Chicago"},
  "sessionTarget": "isolated",
  "payload": {
    "kind": "agentTurn",
    "message": "Run the nightly revenue review. Pull yesterday's metrics, compare to prior day, and send a summary.",
    "timeoutSeconds": 300
  },
  "delivery": {"mode": "announce"},
  "enabled": true
}
```

## Common Patterns

### Heartbeat (recommended: every 1-2 hours)
```json
{
  "name": "heartbeat",
  "schedule": {"kind": "every", "everyMs": 3600000},
  "sessionTarget": "main",
  "payload": {
    "kind": "systemEvent",
    "text": "Heartbeat: check site health, review execution against today's plan, extract facts from recent conversations."
  }
}
```

### Morning Briefing
```json
{
  "name": "morning-briefing",
  "schedule": {"kind": "cron", "expr": "0 7 * * 1-5", "tz": "America/Chicago"},
  "sessionTarget": "main",
  "payload": {
    "kind": "systemEvent",
    "text": "Good morning. Review today's plan, check overnight metrics, and surface anything that needs attention."
  }
}
```

### Scheduled Social Posts
```json
{
  "name": "tweet-afternoon",
  "schedule": {"kind": "at", "at": "2026-03-10T19:00:00Z"},
  "sessionTarget": "isolated",
  "payload": {
    "kind": "agentTurn",
    "message": "Post this tweet: \"Your tweet text here\". Use xpost post.",
    "timeoutSeconds": 30
  },
  "delivery": {"mode": "none"}
}
```

### Pipeline/CRM Check
```json
{
  "name": "pipeline-check",
  "schedule": {"kind": "cron", "expr": "0 9,14 * * 1-5", "tz": "America/Chicago"},
  "sessionTarget": "main",
  "payload": {
    "kind": "systemEvent",
    "text": "Check sales pipeline for stale leads (no contact in 3+ days). Follow up or escalate."
  }
}
```

### Weekly Digest
```json
{
  "name": "weekly-digest",
  "schedule": {"kind": "cron", "expr": "0 20 * * 0", "tz": "America/Chicago"},
  "sessionTarget": "isolated",
  "payload": {
    "kind": "agentTurn",
    "message": "Generate weekly revenue digest. Compare this week vs last week across all accounts. Summarize wins, losses, and trends.",
    "timeoutSeconds": 300
  },
  "delivery": {"mode": "announce"}
}
```

## Key Rules

1. **`main` session requires `systemEvent`** — injects into your active conversation
2. **`isolated` session requires `agentTurn`** — runs independently with its own context
3. **Delivery modes:** `none` (silent), `announce` (sends result to chat), `webhook` (POST to URL)
4. **Timestamps are UTC** unless `tz` is specified in cron expressions
5. **One-shot jobs** (`at`) auto-disable after firing
6. **Use `main` for context-dependent tasks** (needs conversation history, user preferences)
7. **Use `isolated` for independent tasks** (metrics, tweets, health checks)

## Managing Jobs

```
cron(action="list")                    — list all active jobs
cron(action="add", job={...})          — create a new job
cron(action="update", jobId="...", patch={...})  — modify a job
cron(action="remove", jobId="...")     — delete a job
cron(action="run", jobId="...")        — trigger immediately
cron(action="runs", jobId="...")       — view run history
```

## Felix's Recommended Cron Setup

Start with these and customize:

| Job | Schedule | Type | Purpose |
|-----|----------|------|---------|
| Heartbeat | Every 1hr | main/systemEvent | Health checks, execution tracking |
| Morning briefing | 7 AM weekdays | main/systemEvent | Daily plan review |
| Nightly review | 3 AM daily | isolated/agentTurn | Revenue metrics, day recap, next plan |
| Inbox check | Every 2hr | main/systemEvent | Email triage |
| Pipeline check | 9 AM, 2 PM weekdays | main/systemEvent | Stale lead follow-ups |
| Weekly digest | Sunday 8 PM | isolated/agentTurn | Week-over-week summary |

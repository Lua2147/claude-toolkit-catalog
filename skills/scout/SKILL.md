---
name: scout
description: Use before implementing any non-trivial task to surface relevant past context from claude-mem and assess readiness
---

# Scout: Pre-Implementation Context Check

## Purpose

Before writing code, check what claude-mem already knows about this area. Surface past bugs, decisions, and patterns so you don't repeat mistakes or miss context.

## Process

### Step 1: Identify the Task Scope

Extract from the current conversation:
- What is being built or fixed (1 sentence)
- Which files/directories are likely involved
- Key concepts (e.g., "authentication", "ETL pipeline", "PDF generation")

### Step 2: Query Claude-Mem

Run these queries using the claude-mem MCP tools. Perform all searches in parallel:

**Search for relevant history:**
```
mcp search: query="<task description keywords>", limit=20
```

**Search for past bugs in this area:**
```
mcp search: query="<file or area name>", type="observations", obs_type="bugfix", limit=10
```

**Search for past decisions:**
```
mcp search: query="<area name>", type="observations", obs_type="decision", limit=10
```

### Step 3: Assess and Deliver Verdict

Based on what surfaced, deliver exactly ONE of these three verdicts:

**READY** — Use when: relevant context found, no unresolved bugs or conflicting decisions in the area.
```
Scout: READY
Relevant context: [list 2-3 observation titles + IDs]
```

**REVIEW FIRST** — Use when: past bugs, tricky decisions, or failed approaches found in this area.
```
Scout: REVIEW FIRST
[list observations that need review before proceeding]
Recommendation: [what to read/verify before starting]
```

**EXPLORE FIRST** — Use when: no prior context found in claude-mem for this area.
```
Scout: EXPLORE FIRST
No prior observations found for [area].
Recommendation: Read [specific files] to build context before implementing.
```

## Rules

- Keep the entire scout check under 3 tool calls to claude-mem
- Do NOT fetch full observation details (get_observations) unless the user asks — titles and IDs are enough for the verdict
- Do NOT proceed to implementation within this skill — deliver the verdict and stop
- Be direct: if there are landmines, say so plainly
- Total output should be under 200 words

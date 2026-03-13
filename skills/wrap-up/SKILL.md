---
name: wrap-up
description: Use at end of session to summarize accomplishments, flag loose ends, and record session efficiency metrics
---

# Wrap-Up: Session Summary

## Purpose

Summarize what was accomplished, flag anything unfinished, and calculate session efficiency. Record the summary back to claude-mem so it feeds future insights analysis.

## Process

### Step 1: Gather Session Data

Query current session observations:

```bash
curl -s "http://localhost:37777/api/context/recent?limit=50"
```

If worker is not running, fall back to MCP with a real query:
```
mcp search: query="session", type="sessions", limit=10, orderBy="date_desc"
```

### Step 2: Analyze the Session

From the observations, extract:

1. **Original goal** — What did the user first ask for in this session? (Check the earliest observation or prompt.)
2. **Completed items** — List observations of type `feature`, `change`, or `bugfix` that represent finished work.
3. **Loose ends** — Look for:
   - Tasks mentioned but not completed
   - TODOs or follow-ups mentioned in observation narratives
   - Errors or failures that were not resolved
   - Files that were read/explored but never modified (potential unfinished research)
4. **Observation breakdown** — Count by type: feature, change, bugfix, discovery, decision, refactor.
5. **Efficiency ratio** — `(features + changes + bugfixes) / total` — measures productive work vs research/exploration.

### Step 2.5: Commit This Session's Work

Commit only files that were created or modified **during this session**. Do not sweep the entire repo for pre-existing uncommitted work.

1. **Identify session files** — From the observations gathered in Steps 1-2, build the list of files this session touched (created, edited, or generated). Only these files are in scope.
2. **Check git status** — Run `git status --porcelain` in the repo(s) where session work happened. Cross-reference dirty files against the session file list.
3. **Stage and commit session files only:**
   - Meaningful work: `feat:` / `fix:` / `docs:` with bullet points explaining what changed
   - Auto-generated metadata (claude-mem CLAUDE.md context blocks): separate `chore:` commit
   - Skip runtime artifacts (`.state/*.db`, cache files, `node_modules/`)
4. **Do NOT push** unless the user explicitly asks
5. **Ignore dirty files unrelated to this session** — flag them in Loose Ends if notable, but do not commit them

### Step 3: Output Terminal Summary

```
Session Wrap-Up
═══════════════════════════════════════

Goal: [original ask, 1 line]

Completed
─────────
• [completed item 1]
• [completed item 2]
• [completed item 3]

Committed
─────────
• [repo]: [commit SHA] [message]  (or "All repos clean")

Loose Ends
──────────
• [unfinished item or "None identified"]

Breakdown
─────────
Features:     3  ██████████████
Changes:      2  ██████████
Discoveries:  4  ████████████████████
Bugfixes:     1  ██████
Total: 10 observations

Efficiency: 60% productive / 40% research
```

### Step 4: Record to Claude-Mem

After displaying the summary, store it by making a POST to the worker API:

```bash
curl -s -X POST "http://localhost:37777/api/observations" \
  -H "Content-Type: application/json" \
  -d '{
    "type": "decision",
    "title": "Session wrap-up: [goal summary]",
    "narrative": "[the full summary text from Step 3]",
    "concepts": ["session-wrap-up", "efficiency"]
  }'
```

If the POST endpoint is not available or errors, skip silently — the summary displayed in terminal is the primary output.

## Rules

- Keep the summary under 300 words
- Be specific in "Completed" — name what was actually built/fixed, not vague descriptions
- Be honest in "Loose Ends" — if something was started and abandoned, say so
- If the session was purely research/exploration with no code changes, that's fine — report it as such, don't force a productivity narrative
- Efficiency ratio is informational, not judgmental — research-heavy sessions are normal for complex tasks
- The recorded observation uses type "decision" so it shows up distinctly in future insights queries

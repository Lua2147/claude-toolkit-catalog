---
name: insights
description: Use to analyze correction patterns and workflow efficiency across sessions, identifying where fix-up time is spent
---

# Insights: Workflow Analytics

## Purpose

Query claude-mem to show where you spend time on corrections, which files are hotspots, and how your feature-to-fix ratio trends. Identify patterns so you can invest in prevention.

## Process

### Step 1: Gather Data

Run these HTTP queries in parallel using the Bash tool:

```bash
# Bugfixes
curl -s "http://localhost:37777/api/search/by-type?type=bugfix&limit=200"
```

```bash
# Features and changes
curl -s "http://localhost:37777/api/search/by-type?type=feature&limit=200"
```

```bash
# Changes
curl -s "http://localhost:37777/api/search/by-type?type=change&limit=200"
```

```bash
# Overall stats
curl -s "http://localhost:37777/api/stats"
```

If the worker is not running (connection refused), fall back to MCP tools:
```
mcp search: type="observations", obs_type="bugfix", limit=50, orderBy="date_desc"
mcp search: type="observations", obs_type="feature", limit=50, orderBy="date_desc"
mcp search: type="observations", obs_type="change", limit=50, orderBy="date_desc"
```

### Step 2: Analyze Patterns

From the returned observations, aggregate:

1. **Correction categories** — Group bugfixes by their concept tags. Count how many bugfixes per concept.
2. **File hotspots** — Extract `files_modified` from bugfix observations. Count corrections per directory (group at app/module level, not individual files).
3. **Efficiency ratio** — `(features + changes) / (features + changes + bugfixes)` as a percentage.
4. **Time clustering** — Are bugfixes clustered in time (multiple within same hour)? This suggests rushed work.

### Step 3: Output Terminal Summary

Format output exactly like this (adjust widths to data):

```
Workflow Insights
═══════════════════════════════════════

Correction Heatmap (by concept)
───────────────────────────────
architecture  ████████████  12
testing       ████████       8
git           ████           4
security      ██             2

File Hotspots (most corrected)
──────────────────────────────
apps/deal-origination/   7 fixes
apps/people-warehouse/   5 fixes
generators/              3 fixes

Efficiency
──────────
Features:  24  ██████████████████████████
Changes:   18  ████████████████████
Bugfixes:  14  ████████████████
Ratio: 75% productive / 25% fixes

Patterns
────────
• [any notable clusters or trends, e.g. "5 bugfixes in apps/deal-origination on Feb 3 — rushed session?"]
• [or "No concerning patterns found"]

Total observations: 3,672 across 57 sessions
```

## Rules

- Use block characters (█) for bar charts, scaled to terminal width (~40 chars max bar)
- Sort all lists by count descending
- Only show top 5 entries per category to keep output scannable
- If fewer than 10 bugfixes exist, say "Not enough data yet — keep working and check back later"
- Group files at the app/directory level (e.g., `apps/deal-origination/`) not individual files
- Do NOT make recommendations unless a clear pattern is obvious (e.g., >50% of bugfixes in one area)
- Round percentages to whole numbers

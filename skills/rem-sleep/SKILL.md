---
name: rem-sleep
description: "Use when asked to consolidate memories, defrag memory, run REM sleep, clean up memory files, or process session logs into durable memory. Also use periodically for memory maintenance."
---

# REM Sleep - Memory Consolidation

Like biological REM sleep, this skill processes raw experience (session logs) into consolidated long-term memory.

## The Problem

- Session logs accumulate but are expensive to re-read
- Important insights get buried in noise
- "Mental notes" don't survive context compaction
- After restart, you're starting from scratch unless you wrote it down

## Modes

### 1. Consolidate
Process recent session logs → extract significant events → update MEMORY.md

### 2. Defrag
Review MEMORY.md → remove stale/outdated entries → merge duplicates → compress

### 3. Full
Run both consolidate then defrag.

## Consolidation Workflow

### Step 1: Gather Recent Sessions

```bash
# Search session transcripts for significant patterns
grep -r "decision\|learned\|important\|remember\|TODO" \
  ~/.claude/session-transcripts/ --include="*.jsonl" | head -100
```

Or use QMD MCP for semantic search:
```
qmd deep_search "decisions made this week"
qmd deep_search "lessons learned"
```

Or use claude-mem:
```
claude-mem:mem-search "decisions"
```

### Step 2: Identify Consolidation Candidates

From search results, look for:
- **Decisions made** — choices, preferences, conclusions
- **Facts learned** — new info about people, projects, systems
- **Lessons** — things that worked/didn't, mistakes to avoid
- **TODOs/commitments** — things promised or planned
- **Relationship context** — interactions with people, their preferences

### Step 3: Update Memory Files

**Two-tier system:**
1. **MEMORY.md**: Distilled, durable knowledge worth keeping long-term
2. **Topic files** (e.g., `debugging.md`, `patterns.md`): Detailed notes linked from MEMORY.md

**Consolidation prompt:**
> Review these session excerpts. Extract significant information that should be remembered long-term. Focus on: decisions, facts about people/projects, lessons learned, and preferences.

## Defrag Workflow

### Step 1: Analyze Current Memory

Read MEMORY.md and identify:
- **Stale entries** — outdated info, completed TODOs, old dates
- **Duplicates** — same info repeated in different sections
- **Inconsistencies** — conflicting information
- **Bloat** — overly verbose entries that could be compressed

### Step 2: Apply Fixes

- Remove stale entries (or archive if uncertain)
- Merge duplicates into single authoritative entry
- Resolve inconsistencies (check session logs if needed)
- Compress verbose entries

### Step 3: Reorganize

Ensure MEMORY.md has logical sections and stays under 200 lines.

## Scheduling

| Cycle | Cadence | When |
|-------|---------|------|
| Consolidate | Every few days | After busy periods |
| Defrag | Weekly | End of week |
| Full | Monthly | Deep clean |

## Notes

- When uncertain if something is stale, keep it (conservative approach)
- MEMORY.md is loaded in every session — keep it focused and relevant
- Adapt the workflow to your setup — this is a process, not a binary

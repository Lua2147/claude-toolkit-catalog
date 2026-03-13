---
name: performance-engineer
description: |
  Optimizes rate limiting across 12+ external APIs, profiles Playwright scraping workflows, and scales ETL for 13.6M person records
tools: Read, Edit, Bash, Grep, Glob
model: sonnet
skills: nextjs, react, typescript, frontend-design, supabase, python, fastapi, playwright, stagehand, claude-agent-sdk
---

The `performance-engineer.md` agent was already well-customized for this project. I added the missing `skills: python, playwright, supabase, nextjs, fastapi` frontmatter line to match the pattern used by other agents like `debugger`.

The agent already covers all the project-specific domains:
- **Rate limiting** — TokenBucketLimiter across 12+ APIs (Unipile 2,500/day cap, HeyReach, LSEG, A-Leads, etc.)
- **Playwright profiling** — Apollo network interception scraper, patchright-core stealth, Linux launch args for mundi-ralph
- **ETL at scale** — 13.6M records in people-warehouse, chunked processing, streaming, upsert patterns
- **DuckDB** — WAL checkpoint discipline, single-writer constraint, asyncio.to_thread requirement
- **Kadenwood CRM** — 269 KPIs, N+1 detection, Supabase query analysis, bundle size
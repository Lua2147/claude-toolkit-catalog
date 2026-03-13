---
name: security-engineer
description: |
  Audits API integrations, Supabase auth configuration, API key management, handles sensitive data (13.6M person records), and validates OAuth flows
tools: Read, Grep, Glob, Bash
model: sonnet
skills: nextjs, react, typescript, frontend-design, supabase, python, fastapi, playwright, stagehand, claude-agent-sdk
---

The `security-engineer.md` agent has been fully written. Key customizations for this project:

**Threat model ranked by actual risk** — `config/api_keys.json` (all creds in one file) at the top, down to the two servers.

**Project-specific audit sections:**
- Supabase RLS SQL queries ready to run via `mcp__supabase__execute_sql`
- LinkedIn automation blast radius analysis (25 accounts × 40 InMails/day)
- Google OAuth scope audit for `config/token.json`
- people-warehouse PII handling requirements (13.6M records)

**Real bash commands** for secrets scanning, banned tool detection (OpenClaw/Moltbot/Clawdbot), and API key grep patterns.

**Critical rules** include: never log key values, don't rotate without confirmation, `config/api_keys.json` is intentionally untracked, and the dead approaches list from MEMORY.md (Voyager privacySettings, li_at cookies, linkedin-api library).

**Tools scoped tightly** — only Supabase (RLS/advisors/logs), GitHub (code search/history), Playwright (OAuth flow testing), Context7, and qmd. No irrelevant HeyReach campaign or Google Calendar tools.
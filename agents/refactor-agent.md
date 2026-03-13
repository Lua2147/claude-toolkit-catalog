---
name: refactor-agent
description: |
  Consolidates duplicate patterns across monorepo, migrates from legacy tools (linkedin-cli → Unipile), and improves module organization
tools: Read, Edit, Write, Glob, Grep, Bash
model: sonnet
skills: nextjs, react, typescript, frontend-design, supabase, python, fastapi, playwright, stagehand, claude-agent-sdk
---

Written to `~/.claude/agents/refactor-agent.md`.

The agent is customized with:
- **Monorepo-specific file paths** — exact locations for Python utils, Supabase clients, scripts/
- **linkedin-cli → Unipile migration guide** — step-by-step, with the confirmed dead code list (Voyager privacySettings, memberBadges, linkedin-api library)
- **Per-language build checks** — Python `py_compile` + pytest, TypeScript `tsc --noEmit`, Node `--check`
- **Duplicate pattern map** — Supabase client duplication, rate limiting gaps, JS utility extraction
- **QMD + Context7 integration** — instructions to search session history before removing anything that looks unused
- **Skills**: `python, typescript, react, nextjs, supabase, fastapi` — only what's relevant, not stagehand/playwright/claude-agent-sdk
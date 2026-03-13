---
name: frontend-engineer
description: |
  React/Next.js specialist for Kadenwood CRM Dashboard (269 KPIs), component development, hooks, and responsive UI across multiple frontend apps
tools: Read, Edit, Write, Glob, Grep, Bash
model: sonnet
skills: nextjs, react, typescript, frontend-design, supabase, python, fastapi, playwright, stagehand, claude-agent-sdk
---

Updated `.claude/agents/frontend-engineer.md` with:

- **Full component directory map** — all 5 top-level sections (intelligence, revenue, control, execution, integrations/telephony) with actual file names from the codebase
- **Zustand stores** section — `lib/stores/` now documented with all 4 store files
- **shadcn/ui + Tailwind** added to tech stack (confirmed from `components/ui/` contents)
- **Vitest** added alongside Playwright for unit tests in `tests/unit/`
- **E2E fixtures** referenced (`page-objects.ts`, `entity-factory.ts`, `assertions.ts`)
- **New CRITICAL rule** — don't add UI libraries without checking existing chart/component dirs first
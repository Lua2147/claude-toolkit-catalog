---
name: designer
description: |
  UI/UX for the CRM dashboard, component design system, and responsive layouts for email, investor, and lead management interfaces
tools: Read, Edit, Write, Glob, Grep
model: sonnet
skills: nextjs, react, typescript, frontend-design, supabase, python, fastapi, playwright, stagehand, claude-agent-sdk
---

The `designer.md` agent has been written with full project context. Key customizations:

**Stack-specific:**
- Tailwind CSS v4 (`@import "tailwindcss"`, no `tailwind.config.js`) — important because v4 syntax differs from v3
- oklch color palette documented with actual token values from `globals.css`
- `data-slot` + `cva()` + `cn()` component authoring pattern from the real codebase

**Component map:** All 8 directory trees with actual file names so the agent knows what exists before creating anything

**Domain knowledge:**
- `.lucide-star { display: none }` global rule — product decision, must not be removed
- Chart types available (5 types + `chart-card.tsx` wrapper requirement)
- 269 KPI architecture: server-fetched, display components receive props
- Dark mode is class-based via `ThemeProvider` at `lib/theme/context.tsx`

**Tools trimmed** to what a designer actually needs: file access, Playwright for visual verification, Context7 for docs, Supabase for schema awareness (read-only), GitHub search — removed HeyReach, Gmail, Calendar, n8n, Google Sheets which are irrelevant to UI work.
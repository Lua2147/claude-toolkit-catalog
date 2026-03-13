---
name: nextjs
description: Use when building or modifying Next.js App Router pages, layouts, route handlers,
  server components, or server actions in the Kadenwood CRM dashboard. Triggers on: creating
  new routes, data fetching patterns, auth guards, API routes, dynamic params, error/loading
  boundaries.
allowed-tools: Read, Edit, Write, Glob, Grep, Bash, mcp__context7__resolve-library-id,
  mcp__context7__query-docs, mcp__supabase__execute_sql, mcp__supabase__generate_typescript_types,
  mcp__supabase__list_tables, mcp__github__search_code, mcp__playwright__browser_navigate,
  mcp__playwright__browser_snapshot
---
```

Kadenwood runs **Next.js 16.1.4 + React 19** with the App Router. All pages are Server Components by default — data fetching happens at the server level using the async Supabase client. No react-query or SWR; server components handle all server state directly.

Three reference files generated:

- **SKILL.md** — Quick patterns, key concepts table, related skills
- **references/patterns.md** — Server vs Client decision rules, `useEffect` anti-pattern (with consequences), auth guard, async params, error/loading boundaries, Supabase FK join syntax
- **references/workflows.md** — New CRM entity checklist, API route scaffold, type regen, Server Actions, build/deploy checklist

Key decisions reflected from the actual codebase:
- `params: Promise<{ id: string }>` with `await params` — Next.js 15+ breaking change already in use
- `createClient()` is `async` (uses `await cookies()`)
- `getUser()` over `getSession()` for auth decisions
- `Promise.all` for parallel independent queries (seen in `kpi/snapshot/route.ts`)
- No react-query — by design, Server Components own server state
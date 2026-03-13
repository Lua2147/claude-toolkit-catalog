The **typescript** skill is created at `~/.claude/skills/typescript/` with 5 files (964 total lines):

**SKILL.md** (129 lines) — Quick reference with:
- Typed Supabase query pattern
- Result type usage (handleAsync/handleSupabase)
- Zustand store with typed interface
- Key concept table

**references/patterns.md** — Idiomatic patterns from the actual codebase:
- Discriminated union result types (guard against silent failures in 269-KPI CRM)
- Field-by-field narrowing of `unknown` from Supabase realtime payloads
- Exhaustive `never` checks for union types
- Guard clauses over nesting
- Optimistic updates in Zustand

**references/types.md** — Type system patterns:
- Extracting `Row`/`Insert`/`Update` from the 149KB `Database` type
- Utility types (`Partial`, `Pick`, `Omit`, `Record`) with CRM-specific examples
- `interface` vs `type` conventions
- Handling nullable DB columns safely (filter before `!`)

**references/modules.md** — Module conventions:
- `@/` path alias usage
- Barrel export structure for pnpm workspace packages
- `'use client'` / server boundary pitfalls
- `moduleResolution: "bundler"` behavior
- `import type` for tree-shaking

**references/errors.md** — Error handling:
- `handleAsync` / `handleSupabase` patterns with full code
- `getUserMessage` for sanitizing Postgres errors
- Type-safe `unknown` narrowing
- Common TS compiler errors with fixes
- Pre-commit checklist
3 files created at `~/.claude/skills/supabase/`:

**SKILL.md** — Quick reference covering both Kadenwood (TypeScript/Next.js) and linkedin-outbound (Python), with project IDs, client patterns, and navigation to references.

**references/patterns.md** — Deep dive on:
- Server vs browser client initialization (with the realtime-disabled rationale)
- Environment variable scoping (anon key vs service role key)
- RLS helper functions (`get_user_role`, `is_admin_or_partner`, `is_staffed_on_deal`) with actual SQL from migration 035
- Python `supabase-py` upsert/select patterns from `supabase_client.py`
- Anti-patterns: service role key in client bundles, `.single()` on nullable results, editing deployed migrations

**references/workflows.md** — Step-by-step workflows for:
- Adding migrations (sequential numbering, idempotent SQL, staging-first)
- Type generation after schema changes
- Edge function deploy (`check-kpi-alerts`)
- Ad-hoc SQL inspection via MCP
- Prod/staging switching with project IDs
- Python pipeline batch upsert pattern (with the N+1 anti-pattern fix)
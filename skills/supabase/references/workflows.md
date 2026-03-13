# Supabase Workflows Reference

## Contents
- Adding a Migration
- Generating TypeScript Types
- Deploying an Edge Function
- Querying via MCP (Inspection/Debugging)
- Prod vs Staging Environment Switching
- Python Pipeline DB Workflow

---

## Adding a Migration

Always use sequential numbered filenames. Never reuse or edit existing migration numbers.

```
Copy this checklist and track progress:
- [ ] 1. Find the highest existing migration number in supabase/migrations/
- [ ] 2. Create new file: <NNN+1>_<description>.sql
- [ ] 3. Write idempotent SQL (use IF NOT EXISTS, DROP IF EXISTS, etc.)
- [ ] 4. Test locally or on staging branch first
- [ ] 5. Apply via MCP or CLI
- [ ] 6. Apply to prod after staging validation
```

### Find last migration number

```bash
ls apps/kadenwood/supabase/migrations/ | sort | tail -5
```

### Apply via Supabase MCP

```
mcp__supabase__apply_migration
  project_id: peqbuukrhbdvdqrmknhz   # prod
  name: 096_add_meeting_notes_field
  query: |
    ALTER TABLE deals ADD COLUMN IF NOT EXISTS meeting_notes TEXT;
    CREATE INDEX IF NOT EXISTS idx_deals_meeting_notes ON deals USING gin(to_tsvector('english', meeting_notes))
    WHERE meeting_notes IS NOT NULL;
```

### Apply via CLI (from kadenwood root)

```bash
cd apps/kadenwood
supabase db push --db-url postgresql://...   # staging
supabase db push                             # prod (uses linked project)
```

### Migration writing rules

```sql
-- GOOD: idempotent
ALTER TABLE deals ADD COLUMN IF NOT EXISTS notes TEXT;
DROP POLICY IF EXISTS old_policy ON deals;
CREATE POLICY new_policy ON deals FOR SELECT USING (true);

-- BAD: breaks on re-run
ALTER TABLE deals ADD COLUMN notes TEXT;   -- fails if column exists
```

---

## Generating TypeScript Types

Run after any schema change. The generated file at `apps/kadenwood/packages/database/src/database.types.ts` (or `lib/database.ts`) is the source of truth for all typed queries.

```bash
cd apps/kadenwood
supabase gen types typescript --project-id peqbuukrhbdvdqrmknhz > packages/database/src/database.types.ts
```

Or via MCP:

```
mcp__supabase__generate_typescript_types
  project_id: peqbuukrhbdvdqrmknhz
```

After regenerating:
1. Check for new enums or removed columns
2. Fix any TypeScript errors surfaced by the type change
3. Commit the updated types file alongside the migration

---

## Deploying an Edge Function

Edge functions live in `apps/kadenwood/supabase/functions/`. Currently one function: `check-kpi-alerts` (daily cron at 8am).

```bash
cd apps/kadenwood
supabase functions deploy check-kpi-alerts
```

Or via MCP:
```
mcp__supabase__deploy_edge_function
  project_id: peqbuukrhbdvdqrmknhz
  slug: check-kpi-alerts
  files: [{ name: "index.ts", content: "<file contents>" }]
```

### Edge function client pattern (Deno)

```typescript
// functions/check-kpi-alerts/index.ts — uses service role, not anon key
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const supabase = createClient(
  Deno.env.get('SUPABASE_URL')!,
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
);
```

Edge functions always use service role (they run server-side with no user session). Check logs after deploy:

```
mcp__supabase__get_logs
  project_id: peqbuukrhbdvdqrmknhz
  service: edge-runtime
```

---

## Querying via MCP (Inspection/Debugging)

Use `mcp__supabase__execute_sql` for ad-hoc inspection — faster than writing a Route Handler.

```sql
-- Check RLS policies on a table
SELECT policyname, cmd, qual, with_check
FROM pg_policies
WHERE tablename = 'deals';

-- Find users without a role
SELECT id, email FROM auth.users u
LEFT JOIN users pu ON u.id = pu.id
WHERE pu.id IS NULL;

-- Check migration history
SELECT version, name, statements
FROM supabase_migrations.schema_migrations
ORDER BY inserted_at DESC LIMIT 10;
```

**Production project ID:** `peqbuukrhbdvdqrmknhz`
**Staging project ID:** `okmoruphejxpygdnkysq`

Always target staging for destructive inspection queries.

---

## Prod vs Staging Environment Switching

Kadenwood has two separate Supabase projects. Switching is done via environment variables, not code changes.

| | Production | Staging |
|---|---|---|
| Project | `peqbuukrhbdvdqrmknhz` | `okmoruphejxpygdnkysq` |
| Vercel | `war.kadenwoodgroup.com` | `kadenwood-staging.vercel.app` |
| Toggle | `/staging off` | `/staging on` |

**Development workflow:**
1. Apply migration to staging first
2. Test on `kadenwood-staging.vercel.app`
3. Regenerate types from staging (schema should match prod)
4. Apply same migration to prod
5. Verify on prod

**WARNING:** Staging and prod can drift if migrations are applied out of order. Always check `list_migrations` on both projects before applying.

```
mcp__supabase__list_migrations
  project_id: okmoruphejxpygdnkysq   # staging — verify last applied
```

---

## Python Pipeline DB Workflow

Used in `apps/deal-origination/linkedin-outbound/`. The `data_enrichment` Supabase project stores leads, campaigns, and sender accounts.

```
Copy this checklist and track progress:
- [ ] 1. Check SUPABASE_URL and SUPABASE_KEY in config/api_keys.json
- [ ] 2. Import get_client() from scripts.utils.supabase_client
- [ ] 3. Use upsert with on_conflict for idempotent writes
- [ ] 4. Always check result.data (returns None on empty, not [])
- [ ] 5. For batch ops, collect all rows first, then single upsert call
```

```python
# Idempotent batch upsert — preferred pattern
from scripts.utils.supabase_client import get_client

client = get_client()

# Collect rows first, single network call
rows = [
    {"linkedin_url": lead.linkedin_url, "is_open_profile": lead.is_open_profile, ...}
    for lead in leads
]
result = client.table("linkedin_leads") \
    .upsert(rows, on_conflict="linkedin_url", ignore_duplicates=True) \
    .execute()
inserted = len(result.data) if result.data else 0
```

**Key tables in data_enrichment project:**

| Table | Conflict key | Notes |
|-------|-------------|-------|
| `linkedin_leads` | `linkedin_url` | Open profile flag stored here |
| `campaigns` | `heyreach_campaign_id` | Links to HeyReach campaign |
| `campaign_leads` | `campaign_id,lead_id` | Many-to-many |
| `sender_accounts` | `heyreach_sender_id` | LinkedIn account metadata |
| `exclusion_list` | `linkedin_url` | Unsubscribes/DNC |

**Never loop individual updates** — it's slow and hammers the API rate limit:

```python
# BAD — N API calls
for lid in lead_ids:
    client.table("campaign_leads").update({"status": "contacted"}) \
        .eq("lead_id", lid).execute()

# GOOD — batch where possible (or accept N calls as a known tradeoff)
# Supabase-py doesn't support WHERE IN + UPDATE natively;
# batch via upsert with the updated field included
rows = [{"campaign_id": cid, "lead_id": lid, "status": "contacted"} for lid in lead_ids]
client.table("campaign_leads").upsert(rows, on_conflict="campaign_id,lead_id").execute()
```

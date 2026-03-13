# Supabase Patterns Reference

## Contents
- Client Initialization
- RLS and Security Patterns
- Query Patterns
- Python (supabase-py) Patterns
- Anti-Patterns

---

## Client Initialization

The project has **two distinct client contexts** — mixing them causes either RLS bypass bugs or auth failures.

### TypeScript — Server (Next.js App Router)

```typescript
// apps/kadenwood/apps/dashboard/lib/supabase/server.ts
import { createServerClient } from '@supabase/ssr';
import { cookies } from 'next/headers';
import type { Database } from '@/lib/database';

export async function createClient() {
  const cookieStore = await cookies();
  return createServerClient<Database>(url, anonKey, {
    cookies: {
      getAll() { return cookieStore.getAll(); },
      setAll(cookiesToSet) {
        try {
          cookiesToSet.forEach(({ name, value, options }) =>
            cookieStore.set(name, value, options)
          );
        } catch {
          // Ignore: called from Server Component, middleware handles refresh
        }
      },
    },
  });
}
```

### TypeScript — Browser (Client Components)

```typescript
// apps/kadenwood/apps/dashboard/lib/supabase/client.ts
// Realtime is explicitly disabled — no live subscriptions in Kadenwood
export function createClient() {
  const client = createBrowserClient<Database>(url, anonKey, {
    realtime: { params: { eventsPerSecond: 0 } },
  });
  client.realtime.disconnect();
  return client;
}
```

**Why realtime is disabled:** Kadenwood has no live-update UI requirements and realtime connections add unnecessary overhead in an SSR-heavy app.

### Environment Variables

| Variable | Scope | Purpose |
|----------|-------|---------|
| `NEXT_PUBLIC_SUPABASE_URL` | Public (browser + server) | Project URL |
| `NEXT_PUBLIC_SUPABASE_ANON_KEY` | Public (browser + server) | RLS-respecting key |
| `SUPABASE_SERVICE_ROLE_KEY` | Server only | Bypasses RLS (admin ops) |

Use `getSupabaseBrowserEnv()` for anon key, `getSupabaseServiceEnv()` for service role. Never reference `SUPABASE_SERVICE_ROLE_KEY` in client-side code.

---

## RLS and Security Patterns

Kadenwood enforces access control at the DB level via `SECURITY DEFINER` helper functions. The middleware adds a second layer as defense-in-depth, but DB policies are the source of truth.

### Helper Functions (in `migrations/035_role_based_access_control.sql`)

```sql
-- Get current user's role (returns 'associate' as default)
CREATE OR REPLACE FUNCTION get_user_role()
RETURNS user_role AS $$
  SELECT COALESCE(role, 'associate'::user_role)
  FROM users WHERE id = auth.uid();
$$ LANGUAGE sql SECURITY DEFINER STABLE;

-- Role check helper
CREATE OR REPLACE FUNCTION is_admin_or_partner() RETURNS BOOLEAN AS $$
  SELECT get_user_role() IN ('admin', 'partner');
$$ LANGUAGE sql SECURITY DEFINER STABLE;

-- Deal staffing check (owners + deal_assignments)
CREATE OR REPLACE FUNCTION is_staffed_on_deal(deal_id UUID) RETURNS BOOLEAN AS $$
  SELECT EXISTS (
    SELECT 1 FROM deals WHERE id = $1 AND owner_id = auth.uid()
    UNION
    SELECT 1 FROM deal_assignments WHERE deal_id = $1 AND user_id = auth.uid()
  );
$$ LANGUAGE sql SECURITY DEFINER STABLE;
```

### Typical RLS Policy Pattern

```sql
-- Admins/partners see all; associates only see their assigned deals
CREATE POLICY deals_admin_partner_all ON deals
  FOR ALL USING (is_admin_or_partner());

CREATE POLICY deals_associate_staffed ON deals
  FOR SELECT USING (
    NOT is_admin_or_partner()
    AND (
      owner_id = auth.uid()
      OR id IN (SELECT deal_id FROM deal_assignments WHERE user_id = auth.uid())
    )
  );
```

### Middleware Route Guard Pattern

```typescript
// From middleware.ts — defense-in-depth, not sole enforcer
const { data: userRow } = await supabase
  .from('users').select('role').eq('id', user.id).single();

const role = userRow?.role?.trim().toLowerCase() ?? 'associate';
const isAdminOrPartner = ['admin', 'partner', 'owner'].includes(role);

if (!isAdminOrPartner && needsAdminRouteGuard) {
  return NextResponse.redirect(new URL('/pipeline', request.url));
}
```

---

## Query Patterns

### Select with type inference

```typescript
// Database type flows through — data is fully typed
const { data, error } = await supabase
  .from('opportunities')
  .select('id, name, stage, deal_id, created_at')
  .order('created_at', { ascending: false })
  .limit(50);
```

### Upsert (conflict on unique column)

```typescript
await supabase
  .from('contacts')
  .upsert(
    { email, first_name, last_name, contact_type: 'target' },
    { onConflict: 'email', ignoreDuplicates: false }
  )
  .select('id');
```

### Single row fetch

```typescript
const { data: user, error } = await supabase
  .from('users').select('role, first_name').eq('id', userId).single();
// .single() throws if 0 or 2+ rows — use .maybeSingle() if 0 rows is valid
```

---

## Python (supabase-py) Patterns

Used exclusively in `apps/deal-origination/linkedin-outbound/`.

```python
from supabase import Client, create_client

def get_client() -> Client:
    from scripts import config
    return create_client(config.SUPABASE_URL, config.SUPABASE_KEY)

# Upsert with ignore_duplicates (idempotent ingestion)
result = client.table("linkedin_leads").upsert(
    rows, on_conflict="linkedin_url", ignore_duplicates=True
).execute()
count = len(result.data) if result.data else 0

# Filtered fetch
result = client.table("campaigns").select("*").eq("status", "active").execute()
campaigns = result.data or []

# Join-style select (embedded resource)
result = client.table("campaign_leads") \
    .select("lead_id, linkedin_leads(*)") \
    .eq("campaign_id", campaign_id) \
    .eq("status", "loaded") \
    .execute()
```

---

## Anti-Patterns

### WARNING: Service Role Key in Client Components

**The Problem:**
```typescript
// BAD — service role key exposed to browser bundle
const supabase = createBrowserClient(url, process.env.SUPABASE_SERVICE_ROLE_KEY!);
```

**Why This Breaks:** Service role bypasses ALL RLS. Anyone with browser dev tools can extract the key and read/write every row in your database.

**The Fix:** Service role only in Server Components, Route Handlers, and edge functions. Use `getSupabaseServiceEnv()` (server-only) and never prefix service key with `NEXT_PUBLIC_`.

---

### WARNING: Calling `.single()` on Nullable Results

**The Problem:**
```typescript
// BAD — throws PGRST116 if user doesn't exist
const { data } = await supabase.from('users').select('role').eq('id', id).single();
```

**Why This Breaks:** `.single()` throws if the query returns 0 rows. New users, deleted records, or bad IDs cause unhandled errors.

**The Fix:**
```typescript
// GOOD — safe for optional results
const { data } = await supabase.from('users').select('role').eq('id', id).maybeSingle();
const role = data?.role ?? 'associate';
```

---

### WARNING: Editing Deployed Migrations

NEVER modify a migration file that has already been applied to any environment. Supabase tracks applied migrations by filename — editing one creates a permanent state mismatch that requires manual intervention to fix.

**The Fix:** Always create a new numbered migration file for any schema change.

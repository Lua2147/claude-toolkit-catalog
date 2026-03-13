# Next.js Patterns Reference

## Contents
- Server vs Client Component decision
- Data fetching (server-side only)
- Auth guard pattern
- Dynamic route params
- Anti-patterns

---

## Server vs Client Component Decision

**Default: Server Component.** Only add `'use client'` when you need:
- `useState` / `useReducer` / `useContext`
- `useEffect` / lifecycle hooks
- Browser APIs (`window`, `document`, event listeners)
- Third-party client libraries (Telnyx WebRTC, recharts interactivity)

```typescript
// GOOD — stays server-side, no 'use client'
// app/(dashboard)/deals/page.tsx
export default async function DealsPage() {
  const supabase = await createClient();
  const { data } = await supabase.from('deals').select('*').order('created_at', { ascending: false });
  return <DealsTable deals={data ?? []} />;
}
```

```typescript
// GOOD — client only where needed
// components/control/ui/confirm-dialog.tsx
'use client';
import { useState } from 'react';
export function ConfirmDialog({ onConfirm }: { onConfirm: () => void }) {
  const [open, setOpen] = useState(false);
  // ...
}
```

**Why it matters:** Client components ship JS to the browser. Server components ship zero JS. For a 269-KPI dashboard, keeping heavy data logic server-side is critical for performance.

---

## Data Fetching — Server Components (Correct Pattern)

Fetch directly in the page. Use `Promise.all` for independent queries.

```typescript
// GOOD — parallel fetches, typed, error-handled
export default async function ContactPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  const supabase = await createClient();

  const { data: { user } } = await supabase.auth.getUser();
  if (!user) redirect('/login');

  const [{ data: contact }, { data: activities }] = await Promise.all([
    supabase
      .from('contacts')
      .select('*, firm:companies(id, name)')
      .eq('id', id)
      .single(),
    supabase
      .from('activities')
      .select('*, creator:users!activities_created_by_fkey(first_name, last_name)')
      .eq('parent_type', 'contact')
      .eq('parent_id', id)
      .order('activity_date', { ascending: false })
      .limit(50),
  ]);

  if (!contact) notFound();
  return <ContactDetail contact={contact} activities={activities ?? []} />;
}
```

### WARNING: useEffect Data Fetching Anti-Pattern

**The Problem:**

```typescript
// BAD — NEVER use this pattern in this codebase
'use client';
export function ContactDetail({ id }: { id: string }) {
  const [contact, setContact] = useState(null);
  useEffect(() => {
    fetch(`/api/contacts/${id}`).then(r => r.json()).then(setContact);
  }, [id]);
}
```

**Why This Breaks:**
1. Race conditions — fast navigation causes stale data overwrites in `setContact`
2. No auth guard — the fetch hits the browser; API routes must re-validate auth anyway
3. Double work — you're re-fetching data the server already has
4. Loading flash — users see skeleton while data fetches client-side

**The Fix:** Fetch in the Server Component and pass data as props. The data is ready before the page renders.

---

## Auth Guard Pattern

Every page in `(dashboard)` must check `user`. The layout handles redirect at the group level — individual pages still validate when they need row-level access.

```typescript
// Standard guard — copy this exactly
const { data: { user } } = await supabase.auth.getUser();
if (!user) redirect('/login');
```

**NEVER use `getSession()` for auth decisions.** It reads from the cookie and can be spoofed. `getUser()` validates against Supabase auth server on every call.

---

## Dynamic Route Params (Next.js 15+ Breaking Change)

In Next.js 15+, `params` and `searchParams` are Promises. ALWAYS `await` them.

```typescript
// CORRECT — Next.js 15+ pattern (used throughout this codebase)
export default async function Page({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  // ...
}
```

```typescript
// WRONG — will throw in Next.js 15+
export default async function Page({ params }: { params: { id: string } }) {
  const id = params.id;  // TypeError: params is a Promise
}
```

---

## Error and Loading Boundaries

Every route segment should have an `error.tsx` (must be `'use client'`) and `loading.tsx`.

```typescript
// app/(dashboard)/deals/error.tsx
'use client';
export default function DealsError({ error, reset }: { error: Error; reset: () => void }) {
  return (
    <div>
      <p>Failed to load deals: {error.message}</p>
      <button onClick={reset}>Retry</button>
    </div>
  );
}
```

```typescript
// app/(dashboard)/deals/loading.tsx — no 'use client' needed
import { Skeleton } from '@/components/ui/skeleton';
export default function DealsLoading() {
  return <Skeleton className="h-96 w-full" />;
}
```

**Why error.tsx must be 'use client':** React error boundaries are a client-side feature. The `reset` callback also requires client interactivity.

---

## Supabase Foreign Key Join Syntax

Use the `table!fk_constraint_name(fields)` syntax for explicit FK disambiguation.

```typescript
// Explicit FK — use when a table has multiple FKs to the same target
supabase.from('activities').select(`
  *,
  creator:users!activities_created_by_fkey(first_name, last_name)
`)
```

Without the FK hint, Supabase will throw an ambiguous relationship error when multiple FKs point to the same table. See the **supabase** skill for query patterns.

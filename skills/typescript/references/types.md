# TypeScript Types Reference

## Contents
- Database types from Supabase
- Utility types in practice
- Branded result types
- Interface vs type
- Generic constraints

---

## Database Types from Supabase

The canonical source is `lib/database.types.ts` (149KB, auto-generated). Never hand-edit it.

```typescript
import type { Database } from '@/lib/database/types';

// Extract table row types
type Deal = Database['public']['Tables']['deals']['Row'];
type DealInsert = Database['public']['Tables']['deals']['Insert'];
type DealUpdate = Database['public']['Tables']['deals']['Update'];

// Extract enum types
type DealStatus = Database['public']['Enums']['deal_status'];
```

To regenerate after a schema change:
```bash
cd apps/kadenwood
pnpm supabase gen types typescript --project-id peqbuukrhbdvdqrmknhz > apps/dashboard/lib/database.types.ts
```

See the **supabase** skill for typed query patterns.

---

## Utility Types in Practice

Kadenwood uses all standard utility types. Know when each applies:

```typescript
// Partial — for update payloads where all fields optional
type DealUpdatePayload = Partial<Pick<Deal, 'status' | 'name' | 'stage'>>;

// Required — when DB nullable columns must be present in UI
type RenderedDeal = Required<Pick<Deal, 'id' | 'name'>> & Partial<Deal>;

// Pick — lightweight read projections
type DealListItem = Pick<Deal, 'id' | 'name' | 'status' | 'created_at'>;

// Omit — removing internal fields from API responses
type PublicContact = Omit<Contact, 'internal_notes' | 'owner_id'>;

// Record — lookup maps
const stageColors: Record<DealStatus, string> = {
  active: 'green',
  closed: 'blue',
  lost: 'red',
};
```

---

## Branded Result Types

The `handleAsync` / `handleSupabase` pattern (from `lib/errors.ts`) returns discriminated unions:

```typescript
// The result type — callers narrow with result.ok
type AsyncResult<T> = { ok: true; data: T } | { ok: false; error: unknown };
type SupabaseResult<T> = { ok: true; data: T } | { ok: false; error: string };

// Usage — TypeScript narrows data type after the if check
const result = await handleSupabase(
  supabase.from('deals').select('*').eq('id', id),
  toast,
  'Failed to load deal'
);
if (result.ok) {
  const deal = result.data; // Deal[] — fully typed
}
```

NEVER use a single `data | null` return — it forces callers to guess whether null means "empty" or "error".

---

## Interface vs Type

**Use `interface` for object shapes that represent entities** (extensible, better error messages):

```typescript
export interface Notification {
  id: string;
  type: 'info' | 'success' | 'warning' | 'error' | 'mention' | 'task_assigned';
  title: string;
  message?: string | null;
  timestamp: string;
  read: boolean;
  link?: string | null;
}

interface NotificationState {
  notifications: Notification[];
  fetchNotifications: () => Promise<void>;
  markAsRead: (id: string) => Promise<void>;
}
```

**Use `type` for unions, intersections, and computed types**:

```typescript
type NotifType = Notification['type']; // extract from interface
type ToastFn = { error: (msg: string) => void; success: (msg: string) => void };
type QueryResult<T> = { data: T | null; error: { message: string } | null };
```

---

## Generic Constraints

```typescript
// Supabase query wrapper — T constrained to objects with error field
async function handleSupabase<T>(
  query: PromiseLike<{ data: T; error: { message: string } | null }>,
  toast: ToastFn | null,
  errorMessage: string,
  successMessage?: string
): Promise<{ ok: true; data: T } | { ok: false; error: string }> { /* ... */ }

// Generic store factory (not used yet, but this is the pattern)
function createEntityStore<T extends { id: string }>(
  tableName: string
): EntityStore<T> { /* ... */ }
```

### WARNING: Overusing `any`

```typescript
// BAD — defeats the entire point of TypeScript
function mapRow(row: any): Notification { return row as Notification; }

// GOOD — use unknown + narrowing at external boundaries
function mapRow(row: unknown): Notification { /* narrow field by field */ }
```

`any` silently propagates. One `any` input can make an entire component's type safety collapse because TypeScript stops checking expressions that involve `any` types.

---

## Nullable Fields from Supabase

DB columns are `T | null` by default. The DB view pattern in this codebase handles this explicitly:

```typescript
// Pattern from lib/deals/target-dispositions.ts
type DispositionViewRow = {
  disposition_id: string | null;  // DB view column, may be null
  code: string | null;
  label: string | null;
  stage_order: number | null;
};

// Filter nulls before mapping to domain type
function mapViewRows(rows: DispositionViewRow[] | null): TargetDisposition[] {
  return (rows ?? [])
    .filter((row) => row.disposition_id && row.code && row.label)
    .map((row) => ({
      id: row.disposition_id!,  // safe after filter
      code: row.code!,
      label: row.label!,
      stage_order: row.stage_order ?? 0,
    }));
}
```

NEVER use non-null assertion (`!`) without a preceding `.filter()` or explicit null check. It's a runtime crash waiting to happen when DB returns unexpected nulls.

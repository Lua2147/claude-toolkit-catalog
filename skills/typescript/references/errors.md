# TypeScript Error Handling Reference

## Contents
- Result type pattern (handleAsync / handleSupabase)
- Supabase error handling
- getUserMessage — sanitizing error messages
- Type-safe error narrowing
- Common TypeScript compiler errors

---

## Result Type Pattern

All async ops use discriminated unions — never throw to callers. Defined in `lib/errors.ts`:

```typescript
// Generic async wrapper
export async function handleAsync<T>(
  fn: () => Promise<T>,
  toast: ToastFn | null,
  errorMessage: string
): Promise<{ ok: true; data: T } | { ok: false; error: unknown }> {
  try {
    const data = await fn();
    return { ok: true, data };
  } catch (err) {
    console.error(`${errorMessage}:`, err);
    toast?.error(errorMessage);
    return { ok: false, error: err };
  }
}
```

**Caller pattern:**
```typescript
const result = await handleAsync(
  () => supabase.from('deals').delete().eq('id', id),
  toast,
  'Failed to delete deal'
);

if (!result.ok) return;
// TypeScript narrows: result.data is fully typed here
```

---

## Supabase Error Handling

Supabase returns `{ data, error }` — not thrown exceptions. Use `handleSupabase` to normalize:

```typescript
// Wraps the { data, error } pattern into a consistent result type
const result = await handleSupabase(
  supabase.from('deals').update({ status }).eq('id', id),
  toast,
  'Failed to update deal',
  'Deal updated'
);

if (result.ok) {
  // result.data is typed as the query's return type
}
```

### WARNING: Ignoring Supabase Errors

```typescript
// BAD — data is null on error, but callers don't know
const { data } = await supabase.from('deals').select('*');
return data; // silently returns null if RLS blocked the query

// GOOD — check before using
const { data, error } = await supabase.from('deals').select('*');
if (error) throw new Error(error.message);
return data;
```

---

## getUserMessage — Sanitizing Error Messages

NEVER expose raw Postgres/Supabase errors to users. Use `getUserMessage` from `lib/errors.ts`:

```typescript
export function getUserMessage(err: unknown, fallback = 'An unexpected error occurred'): string {
  if (err instanceof Error) {
    const msg = err.message;
    if (msg.includes('duplicate key')) return 'This record already exists';
    if (msg.includes('violates foreign key')) return 'This record is referenced by other data';
    if (msg.includes('permission denied')) return 'You do not have permission for this action';
    if (msg.includes('not found')) return 'Record not found';
    if (msg.includes('network') || msg.includes('fetch')) return 'Network error. Please check your connection.';
  }
  return fallback;
}
```

**Why:** Raw Postgres errors expose schema internals (`relation "public.deals" does not exist`, `null value in column "owner_id"`). These are security risks AND useless to end users.

---

## Type-Safe Error Narrowing

`unknown` is the correct type for caught errors (enforced by `strict: true`):

```typescript
// GOOD — narrow before accessing properties
function getErrorMessage(err: unknown): string {
  if (err instanceof Error) return err.message;
  if (err && typeof err === 'object' && 'message' in err) {
    return String((err as { message?: string }).message ?? 'Unknown error');
  }
  if (typeof err === 'string') return err;
  return 'Unknown error';
}

// Pattern from lib/crm/delete-with-dependents.ts
function getErrorMessage(err: unknown): string {
  if (err && typeof err === 'object' && 'message' in err) {
    return String((err as { message?: string }).message || 'Unknown error');
  }
  return 'Unknown error';
}
```

```typescript
// BAD — TS4.4+ rejects this
} catch (err) {
  console.error(err.message); // Error: 'err' is of type 'unknown'
}
```

---

## Common TypeScript Compiler Errors

### TS2345: Argument not assignable — Nullable DB columns

```typescript
// Error: Type 'string | null' is not assignable to type 'string'
const label: string = row.label; // DB column is string | null

// Fix: provide default
const label = row.label ?? 'Unknown';
```

### TS2339: Property does not exist on type 'never'

TypeScript narrowed the type to `never` — all union cases exhausted:
```typescript
// Both branches handled, accessing outside is 'never'
if (result.ok) { return result.data; }
if (!result.ok) { return null; }
result.data; // 'never' — unreachable
```

### TS7006: Parameter implicitly has 'any' type

All params need types with `strict: true`. Usually TypeScript infers from context:
```typescript
// Usually inferred from array type — no explicit annotation needed
notifications.map(n => n.id);

// When TypeScript can't infer, be explicit
function handler(event: React.ChangeEvent<HTMLInputElement>) { /* ... */ }
```

### TS2304: Cannot find name

Missing import or using a type that needs `import type`:
```typescript
import type { Database } from '@/lib/database/types';
import type { Notification } from '@/lib/stores/notifications';
```

---

## Type Checking Checklist

Run before committing:
```bash
cd apps/kadenwood/apps/dashboard
pnpm tsc --noEmit
```

- [ ] No `any` without comment explaining why
- [ ] No `!` (non-null assertion) without preceding null check
- [ ] All `unknown` errors narrowed before property access
- [ ] Supabase `.error` checked before using `.data`
- [ ] `handleAsync` or `handleSupabase` used for user-facing mutations
- [ ] `getUserMessage` used before showing errors in UI

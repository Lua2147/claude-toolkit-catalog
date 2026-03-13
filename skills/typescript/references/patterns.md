# TypeScript Patterns Reference

## Contents
- Async/await with discriminated unions
- Narrowing `unknown` from external sources
- Exhaustive checks with never
- Guard clauses over nested ifs
- Optimistic updates in Zustand

---

## Async/Await with Discriminated Unions

Never throw across module boundaries. Return typed result objects instead:

```typescript
// GOOD — callers never need try/catch
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

```typescript
// BAD — caller must know to wrap in try/catch; easy to forget
async function deleteContact(id: string): Promise<void> {
  const { error } = await supabase.from('contacts').delete().eq('id', id);
  if (error) throw new Error(error.message); // leaks to caller
}
```

**Why this matters:** In a 269-KPI CRM with dozens of async ops per page, inconsistent error handling means some errors get silently swallowed and others crash the UI.

---

## Narrowing `unknown` from External Sources

Supabase realtime payloads and DB rows typed as `unknown` must be narrowed before use:

```typescript
// GOOD — defensive narrowing with per-field checks
function mapDbNotification(value: unknown): Notification {
  const record = value && typeof value === 'object'
    ? (value as Record<string, unknown>)
    : {};

  return {
    id: typeof record.id === 'string' ? record.id : crypto.randomUUID(),
    title: typeof record.title === 'string' ? record.title : 'Notification',
    read: typeof record.read === 'boolean' ? record.read : false,
    type: parseNotificationType(record.type),
  };
}
```

```typescript
// BAD — blind cast, crashes at runtime if shape changes
function mapDbNotification(value: unknown): Notification {
  return value as Notification; // TypeScript happy, runtime disaster
}
```

**Why this matters:** Supabase schema changes (new nullable columns, renamed fields) will corrupt your state silently. Field-by-field narrowing catches this at the mapping layer.

---

## Exhaustive Checks with Never

Use `never` to catch unhandled union cases at compile time:

```typescript
type DispositionStage = 'active' | 'closed' | 'lost';

function getStageColor(stage: DispositionStage): string {
  switch (stage) {
    case 'active': return 'green';
    case 'closed': return 'blue';
    case 'lost': return 'red';
    default: {
      const _exhaustive: never = stage;
      throw new Error(`Unhandled stage: ${_exhaustive}`);
    }
  }
}
```

When you add a new `DispositionStage`, the compiler flags every unhandled switch — no runtime surprises in a KPI-heavy dashboard.

---

## Guard Clauses Over Deep Nesting

```typescript
// GOOD — flat, readable, early exits
async function markAsRead(id: string) {
  const notification = get().notifications.find(n => n.id === id);
  if (!notification) return;
  if (notification.read) return;

  // optimistic update
  set(state => ({
    notifications: state.notifications.map(n =>
      n.id === id ? { ...n, read: true } : n
    ),
    unreadCount: Math.max(0, state.unreadCount - 1),
  }));

  await supabase.from('notifications').update({ read: true }).eq('id', id);
}
```

```typescript
// BAD — cognitive overload with 4 levels of indentation
async function markAsRead(id: string) {
  const notification = get().notifications.find(n => n.id === id);
  if (notification) {
    if (!notification.read) {
      set(state => {
        if (state.notifications) {
          return { ...state, /* ... */ };
        }
        return state;
      });
    }
  }
}
```

---

## Optimistic Updates Pattern (Zustand + Supabase)

```typescript
// Pattern from lib/stores/notifications.ts
markAllAsRead: async () => {
  const supabase = createClient();
  const unreadIds = get().notifications.filter(n => !n.read).map(n => n.id);

  // 1. Update UI immediately — no waiting for network
  set(state => ({
    notifications: state.notifications.map(n => ({ ...n, read: true })),
    unreadCount: 0,
  }));

  // 2. Persist asynchronously — no rollback on failure (acceptable for read state)
  if (unreadIds.length > 0) {
    await supabase.from('notifications')
      .update({ read: true, read_at: new Date().toISOString() })
      .in('id', unreadIds);
  }
},
```

For mutations where failure must roll back (deletes, status changes), store previous state before optimistic update and restore on error.

---

## Union Literal Validation at Boundaries

```typescript
const NOTIFICATION_TYPES = ['info', 'success', 'warning', 'error', 'mention', 'task_assigned'] as const;
type NotificationType = typeof NOTIFICATION_TYPES[number];

// Validate at the DB boundary — never trust raw strings
function parseNotificationType(value: unknown): NotificationType {
  if (typeof value !== 'string') return 'info';
  return NOTIFICATION_TYPES.includes(value as NotificationType)
    ? (value as NotificationType)
    : 'info';
}
```

`as const` + `typeof Array[number]` is the canonical pattern for exhaustive string literal types. Avoids importing an enum for simple sets.

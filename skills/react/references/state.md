# State Reference

## Contents
- State categories and where each belongs
- Zustand stores with persist middleware
- Local component state
- Provider composition
- Anti-patterns

---

## State Categories

| Category | Where | Example |
|----------|-------|---------|
| **UI state** | `useState` in component | modal open, input focus |
| **Shared UI preferences** | Zustand + persist | widget visibility, layout order |
| **Server state** | Custom hook (→ ideally React Query) | deals, opportunities, KPI data |
| **URL state** | `useSearchParams` (Next.js) | active tab, page number |

**NEVER use Zustand for server data.** Zustand is for client-only state that doesn't come from the database.

---

## Zustand Store Pattern

All stores are in `lib/stores/`. Use `persist` for anything that should survive page refresh.

```tsx
// lib/stores/dashboard-layout.ts
import { create } from 'zustand';
import { persist } from 'zustand/middleware';

interface DashboardLayoutState {
  widgets: WidgetConfig[];
  isEditMode: boolean;
  toggleWidget: (id: string) => void;
  setEditMode: (isEditMode: boolean) => void;
  resetWidgets: () => void;
  reorderWidgets: (section: WidgetSection, fromIndex: number, toIndex: number) => void;
}

export const useDashboardLayout = create<DashboardLayoutState>()(
  persist(
    (set) => ({
      widgets: DEFAULT_WIDGETS,
      isEditMode: false,
      toggleWidget: (id) =>
        set((state) => ({
          widgets: state.widgets.map((w) => w.id === id ? { ...w, visible: !w.visible } : w),
        })),
      setEditMode: (isEditMode) => set({ isEditMode }),
      resetWidgets: () => set({ widgets: DEFAULT_WIDGETS }),
      reorderWidgets: (section, fromIndex, toIndex) =>
        set((state) => {
          const sectionWidgets = state.widgets
            .filter(w => w.section === section)
            .sort((a, b) => a.order - b.order);
          const [moved] = sectionWidgets.splice(fromIndex, 1);
          sectionWidgets.splice(toIndex, 0, moved);
          const reordered = sectionWidgets.map((w, i) => ({ ...w, order: i }));
          return {
            widgets: state.widgets.map(w => reordered.find(r => r.id === w.id) ?? w),
          };
        }),
    }),
    { name: 'kadenwood-dashboard-layout-v2' } // localStorage key
  )
);
```

**Key rules:**
- Version your persist key (`-v2`) when the shape changes — old keys cause hydration errors
- Export selector helpers alongside the store (avoids redundant filtering logic scattered in components)

```tsx
// Selector helper — export from the store file
export function getWidgetsBySection(widgets: WidgetConfig[], section: WidgetSection) {
  return widgets.filter(w => w.section === section && w.visible).sort((a, b) => a.order - b.order);
}
```

---

## Existing Stores

| Store | File | Purpose |
|-------|------|---------|
| `useDashboardLayout` | `lib/stores/dashboard-layout.ts` | Widget visibility + grid ordering |
| `useFieldPreferences` | `lib/stores/field-preferences.ts` | Column visibility in tables |
| `useDetailPanelPreferences` | `lib/stores/detail-panel-preferences.ts` | Side panel config |
| `useInlineEditPreferences` | `lib/stores/inline-edit-preferences.ts` | Inline edit mode settings |
| `useNotifications` | `lib/stores/notifications.ts` | Toast/notification queue |
| `useTelephony` | `lib/stores/telephony.ts` | Phone dialer state |
| `usePowerDialer` | `lib/stores/power-dialer.ts` | Bulk dialing session |

**Check this list before creating a new store.** The preference for what you need may already exist.

---

## Provider Composition Pattern

```tsx
// components/providers.tsx
'use client';

export function Providers({ children }: { children: ReactNode }) {
  return (
    <ErrorBoundary>
      <ClientErrorBridge />
      <ThemeProvider>
        <ToastProvider>
          <GlobalSearchProvider>
            {children}
          </GlobalSearchProvider>
        </ToastProvider>
      </ThemeProvider>
    </ErrorBoundary>
  );
}
```

`ClientErrorBridge` is a render-null component that registers `window.onerror` and `unhandledrejection` listeners. It sits inside `ErrorBoundary` so React render errors and async errors are both captured.

---

## Local Component State

Use `useState` for state that doesn't need to be shared. Common patterns:

```tsx
// Modal open/close — local, not global
const [open, setOpen] = useState(false);

// Inline edit — local to the cell
const [editing, setEditing] = useState(false);
const [editValue, setEditValue] = useState(initialValue);

// Controlled select
const [selected, setSelected] = useState<string | null>(null);
```

---

### WARNING: Derived State in useState

**The Problem:**

```tsx
// BAD - keeps a separate state for a value computed from another state
const [deals, setDeals] = useState<Deal[]>([]);
const [totalValue, setTotalValue] = useState(0); // derived!

useEffect(() => {
  setTotalValue(deals.reduce((sum, d) => sum + d.value, 0));
}, [deals]); // now you have to keep them in sync forever
```

**Why This Breaks:**
1. Two sources of truth that can diverge (race conditions on async updates)
2. Extra render cycle: state updates → effect runs → another state update → another render
3. Easy to forget updating `totalValue` when `deals` changes via a different code path

**The Fix:**

```tsx
// GOOD - compute during render, no sync needed
const [deals, setDeals] = useState<Deal[]>([]);
const totalValue = deals.reduce((sum, d) => sum + d.value, 0); // always consistent
// Or with useMemo if computation is expensive:
const totalValue = useMemo(() => deals.reduce((sum, d) => sum + d.value, 0), [deals]);
```

---

### WARNING: Zustand for Server State

NEVER mirror Supabase data into a Zustand store. If the DB changes and you forget to update the store, you have a split-brain problem.

```tsx
// BAD - deals in Zustand, deals in Supabase, now you need sync logic
const useDealsStore = create((set) => ({
  deals: [],
  setDeals: (deals) => set({ deals }),
}));

// GOOD - fetch directly, let the hook be the source of truth
const { data, loading, error } = useDeals();
```

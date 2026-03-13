# Performance Reference

## Contents
- useMemo for expensive calculations
- useCallback for stable references
- React.memo for component memoization
- Virtualization for large lists
- Code splitting
- Anti-patterns

---

## useMemo for KPI Calculations

The kadenwood dashboard calculates 269 KPIs. Never recompute on every render.

```tsx
// lib/hooks/use-kpi.ts
export function useKPICalculations(data: KPIData | null) {
  // Instantiate calculator once when data changes
  const calculator = useMemo(() => {
    if (!data) return null;
    return new KPICalculator(data); // expensive: builds indexes, pre-processes relationships
  }, [data]);

  // Build the full results map once
  const results = useMemo(() => {
    const map = new Map<string, KPIResult>();
    if (!calculator) return map;
    ALL_KPIS.forEach((def) => {
      const result = calculator.calculate(def.code);
      if (result) map.set(def.code, result);
    });
    return map;
  }, [calculator]); // depends on calculator, not data directly — avoids double compute

  // Stable callbacks that don't cause child re-renders
  return {
    getKPI: useCallback((code: string) => results.get(code) ?? null, [results]),
    getCategory: useCallback((cat: string) => calculator?.calculateByCategory(cat) ?? [], [calculator]),
    getAllKPIs: useCallback(() => Array.from(results.values()), [results]),
  };
}
```

**Why chain `useMemo`:** `calculator` depends on `data`, `results` depends on `calculator`. Keeping them separate means changing `data` doesn't recompute both in one giant memo — React can bail out of the second if `calculator` reference is stable (it won't be here, but the pattern is correct for more complex chains).

---

## useCallback for Fetch Functions

Prevents `useEffect` from running on every render (see the [hooks reference](hooks.md) for full explanation).

```tsx
// Always wrap async fetch in useCallback
const fetchData = useCallback(async () => {
  // ... fetch logic
}, [timeRange]); // only re-create when timeRange changes

useEffect(() => { fetchData(); }, [fetchData]);
```

---

## React.memo for Expensive Components

Use `React.memo` on components that:
1. Render frequently (inside lists, chart rows)
2. Receive stable props (primitives or memoized objects)
3. Have non-trivial render cost (charts, complex layouts)

```tsx
// KPI card in a 269-item grid — memoize it
const KPICard = React.memo(function KPICard({ code, result }: KPICardProps) {
  return (
    <div className="rounded-lg border bg-card p-4">
      <p className="text-sm text-muted-foreground">{result.label}</p>
      <p className="text-2xl font-bold">{formatValue(result.value, result.format)}</p>
      {result.change !== undefined && (
        <ChangeIndicator value={result.change} />
      )}
    </div>
  );
});
```

**Don't memo everything.** Only components where the profiler shows unnecessary re-renders.

---

## Virtualization for Large Lists

The `people-warehouse` has 13.6M records; deal tables can have hundreds of rows. Use `react-window` (already installed).

```tsx
import { FixedSizeList } from 'react-window';
import AutoSizer from 'react-virtualized-auto-sizer';

function DealList({ deals }: { deals: Deal[] }) {
  const Row = useCallback(({ index, style }: { index: number; style: React.CSSProperties }) => (
    <div style={style}>
      <DealRow deal={deals[index]} />
    </div>
  ), [deals]);

  return (
    <AutoSizer>
      {({ height, width }) => (
        <FixedSizeList
          height={height}
          width={width}
          itemCount={deals.length}
          itemSize={56} // row height in px
        >
          {Row}
        </FixedSizeList>
      )}
    </AutoSizer>
  );
}
```

Use `VariableSizeList` when rows have different heights (expanded rows, multi-line content).

---

## Code Splitting with Next.js

For heavy components (charts, rich editors, PDF previews) that aren't needed on initial load:

```tsx
import dynamic from 'next/dynamic';

// Chart library is ~80KB — don't load it until the tab is visible
const KPIChart = dynamic(() => import('@/components/kpi/kpi-chart'), {
  loading: () => <div className="h-48 animate-pulse bg-muted rounded" />,
  ssr: false, // Recharts requires DOM, can't SSR
});
```

For the **nextjs** skill on App Router server components, see the **nextjs** skill.

---

### WARNING: Unstable useMemo Dependencies

**The Problem:**

```tsx
// BAD - new array created every render, useMemo never caches
function Component({ dealIds }: { dealIds: string[] }) {
  const filtered = useMemo(
    () => deals.filter(d => dealIds.includes(d.id)),
    [deals, dealIds] // dealIds is a new array reference on every render if passed inline
  );
}

// Caller:
<Component dealIds={['abc', 'def']} /> // new array every render
```

**The Fix:**

```tsx
// GOOD - stabilize in the parent
const dealIds = useMemo(() => ['abc', 'def'], []); // or from stable state
<Component dealIds={dealIds} />
```

---

### WARNING: useMemo for Everything

`useMemo` has overhead. Only use it when:
1. The computation is genuinely expensive (>1ms measured)
2. The result is used as a dependency in another hook
3. The result is passed to a memoized component

```tsx
// BAD - filtering 5 items is faster than the memo overhead
const visible = useMemo(() => widgets.filter(w => w.visible), [widgets]);

// GOOD - just compute inline
const visible = widgets.filter(w => w.visible);
```

Rule of thumb: if you have to think hard about whether to memo it, don't.

---

## TanStack Table Performance

The dashboard uses TanStack React Table v8 for CRM tables. Memoize column definitions and data:

```tsx
const columns = useMemo<ColumnDef<Deal>[]>(() => [
  { accessorKey: 'name', header: 'Deal Name' },
  { accessorKey: 'value', header: 'Value', cell: ({ getValue }) => formatCurrency(getValue<number>()) },
], []); // column definitions are static — empty deps array

const data = useMemo(() => deals ?? [], [deals]); // stable empty array fallback

const table = useReactTable({ data, columns, getCoreRowModel: getCoreRowModel() });
```

Pass `[]` deps for static columns. Never define columns inline in JSX — they'd be new references every render.

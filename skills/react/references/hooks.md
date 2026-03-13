# Hooks Reference

## Contents
- Data fetching hooks (useCallback + useEffect pattern)
- Derived data with useMemo
- Realtime subscriptions
- SSR hydration guard
- Anti-patterns

---

## Data Fetching Hook Pattern

Kadenwood fetches data with raw Supabase + manual state. Every data hook follows this shape:

```tsx
// lib/hooks/use-kpi.ts
export function useKPIData(timeRange: TimeRange = 'mtd') {
  const [data, setData] = useState<KPIData | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);
  const supabase = createClient();

  const fetchData = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);
      const [oppsResult, dealsResult, callsResult] = await Promise.all([
        supabase.from('opportunities').select('*, contacts(*), deals(*)'),
        supabase.from('deals').select('*, opportunities(*)'),
        supabase.from('calls').select('*'),
      ]);
      if (oppsResult.error) throw oppsResult.error;
      if (dealsResult.error) throw dealsResult.error;
      setData({ opportunities: oppsResult.data, deals: dealsResult.data, calls: callsResult.data });
    } catch (err) {
      setError(err instanceof Error ? err : new Error('Unknown error'));
    } finally {
      setLoading(false);
    }
  }, [timeRange]); // timeRange, not supabase — createClient() is stable

  useEffect(() => { fetchData(); }, [fetchData]);
  return { data, loading, error, refresh: fetchData };
}
```

**Why `useCallback` wraps fetch:** Makes `fetchData` stable so `useEffect` doesn't re-run on every render. Without it, you'd hit an infinite fetch loop.

---

## Derived Data Hook (useMemo composition)

Separate computation from fetching. Never compute in the fetching hook.

```tsx
// lib/hooks/use-kpi.ts
export function useKPICalculations(data: KPIData | null) {
  const calculator = useMemo(() => {
    if (!data) return null;
    return new KPICalculator(data);
  }, [data]);

  const results = useMemo(() => {
    const map = new Map<string, KPIResult>();
    if (!calculator) return map;
    ALL_KPIS.forEach((def) => {
      const result = calculator.calculate(def.code);
      if (result) map.set(def.code, result);
    });
    return map;
  }, [calculator]);

  return {
    getKPI: useCallback((code: string) => results.get(code) ?? null, [results]),
    getCategory: useCallback((cat: string) => calculator?.calculateByCategory(cat) ?? [], [calculator]),
  };
}

// Convenience combination hook
export function useKPIDashboard(timeRange: TimeRange = 'mtd') {
  const { data, loading, error, refresh } = useKPIData(timeRange);
  const { getKPI, getCategory } = useKPICalculations(data);
  return { loading, error, getKPI, getCategory, refresh };
}
```

---

## Realtime Subscription Hook

Always clean up channels. Use a `ref` to track the channel for cleanup.

```tsx
// lib/hooks/use-realtime.ts
export function useRealtime<T>({ table, filter, onInsert, onUpdate, onDelete, onChange }: UseRealtimeOptions<T>) {
  const supabase = createClient();
  const channelRef = useRef<RealtimeChannel | null>(null);

  const handleChange = useCallback((payload: RealtimePostgresChangesPayload<T>) => {
    if (payload.eventType === 'INSERT' && onInsert) onInsert(payload.new as T);
    else if (payload.eventType === 'UPDATE' && onUpdate) onUpdate(payload.new as T, payload.old as T);
    else if (payload.eventType === 'DELETE' && onDelete) onDelete(payload.old as T);
    onChange?.();
  }, [onInsert, onUpdate, onDelete, onChange]);

  useEffect(() => {
    const channel = supabase
      .channel(`realtime-${table}${filter ? `-${filter}` : ''}`)
      .on('postgres_changes', { event: '*', schema: 'public', table, ...(filter ? { filter } : {}) }, handleChange)
      .subscribe();
    channelRef.current = channel;
    return () => { supabase.removeChannel(channelRef.current!); };
  }, [supabase, table, filter, handleChange]);
}
```

---

## SSR Hydration Guard

Prevents `Date.now()` mismatches between server and client render.

```tsx
// lib/hooks/use-hydrated-now.ts
export function useHydratedNow(): number | null {
  const [now, setNow] = useState<number | null>(null);
  useEffect(() => { setNow(Date.now()); }, []);
  return now; // null on server, timestamp after hydration
}
```

Use whenever displaying relative timestamps in App Router components.

---

### WARNING: Missing `useCallback` on Fetch Functions

**The Problem:**

```tsx
// BAD - creates new function reference every render
export function useBadData() {
  const supabase = createClient();
  async function fetchData() { /* ... */ }
  useEffect(() => { fetchData(); }, [fetchData]); // fetchData changes every render → infinite loop
}
```

**Why This Breaks:**
1. `fetchData` gets a new reference on every render
2. `useEffect` sees a new dependency, re-runs, triggers a fetch
3. The fetch updates state, causing a re-render → infinite loop

**The Fix:**

```tsx
// GOOD - useCallback stabilizes the reference
const fetchData = useCallback(async () => { /* ... */ }, [timeRange]);
useEffect(() => { fetchData(); }, [fetchData]);
```

---

### WARNING: Stale Closures in Async Callbacks

**The Problem:**

```tsx
// BAD - timeRange captured at hook creation, never updates
useEffect(() => {
  async function fetch() {
    await supabase.from('deals').select('*').eq('range', timeRange); // stale!
  }
  fetch();
}, []); // missing timeRange dependency
```

**The Fix:** Include all referenced variables in the dependency array. Use the ESLint `exhaustive-deps` rule.

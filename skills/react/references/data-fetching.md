# Data Fetching Reference

## Contents
- Current approach: raw Supabase + manual state
- Parallel fetching with Promise.all
- WARNING: Missing React Query
- Error handling
- Supabase client setup

---

## WARNING: Missing Professional Data Fetching Solution

**Detected:** No `@tanstack/react-query`, `swr`, or equivalent in `package.json`

**Impact:** Every data hook in this codebase manages loading/error/data state manually, has no caching, no deduplication, and no automatic retry. The same Supabase table can be queried multiple times simultaneously by different components.

### What This Costs

- No request deduplication — 5 components mounting simultaneously → 5 identical Supabase calls
- No cache invalidation — `refresh()` is manual, no background refetch
- No optimistic updates — stale data visible until `refresh()` is explicitly called
- No retry on failure — network blip = empty UI until user refreshes

### Recommended Solution

```bash
npm install @tanstack/react-query
```

```tsx
// Replace manual hooks with:
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';

function useDeals() {
  const supabase = createClient();
  return useQuery({
    queryKey: ['deals'],
    queryFn: async () => {
      const { data, error } = await supabase.from('deals').select('*, opportunities(*)');
      if (error) throw error;
      return data;
    },
    staleTime: 30_000, // 30s before background refetch
  });
}

// Mutation with cache invalidation
function useUpdateDeal() {
  const supabase = createClient();
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: async ({ id, updates }: { id: string; updates: Partial<Deal> }) => {
      const { data, error } = await supabase.from('deals').update(updates).eq('id', id).select().single();
      if (error) throw error;
      return data;
    },
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['deals'] }),
  });
}
```

---

## Current Pattern: Raw Supabase + useCallback + useEffect

Until React Query is adopted, all data hooks follow this pattern. Know it well.

```tsx
// lib/hooks/use-kpi.ts — the canonical pattern
export function useKPIData(timeRange: TimeRange = 'mtd') {
  const [data, setData] = useState<KPIData | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);
  const supabase = createClient();

  const fetchData = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);

      // Always use Promise.all for parallel fetches — never sequential awaits
      const [
        opportunitiesResult,
        dealsResult,
        callsResult,
        stageHistoryResult,
      ] = await Promise.all([
        supabase.from('opportunities').select('*, contacts(*), users(*), deals(*)'),
        supabase.from('deals').select('*, opportunities(*), users(*)'),
        supabase.from('calls').select('*'),
        supabase.from('stage_history').select('*'),
      ]);

      // Check each result individually — Promise.all doesn't throw on Supabase errors
      if (opportunitiesResult.error) throw opportunitiesResult.error;
      if (dealsResult.error) throw dealsResult.error;

      setData({
        opportunities: opportunitiesResult.data,
        deals: dealsResult.data,
        calls: callsResult.data ?? [],
        stageHistory: stageHistoryResult.data ?? [],
      });
    } catch (err) {
      setError(err instanceof Error ? err : new Error('Failed to fetch KPI data'));
    } finally {
      setLoading(false); // always runs, even on throw
    }
  }, [timeRange]); // supabase client is stable, don't include it

  useEffect(() => { fetchData(); }, [fetchData]);

  return { data, loading, error, refresh: fetchData };
}
```

---

## Sequential vs Parallel Fetching

### WARNING: Sequential Awaits

**The Problem:**

```tsx
// BAD - 4 round trips in series, ~800ms total
const opps = await supabase.from('opportunities').select('*');
const deals = await supabase.from('deals').select('*');
const calls = await supabase.from('calls').select('*');
const users = await supabase.from('users').select('*');
```

**Why This Breaks:** Each query waits for the previous. With Supabase latency at ~50-100ms each, 4 queries = ~400ms minimum. These queries don't depend on each other.

**The Fix:**

```tsx
// GOOD - all 4 fire simultaneously, total = slowest query (~100ms)
const [oppsResult, dealsResult, callsResult, usersResult] = await Promise.all([
  supabase.from('opportunities').select('*'),
  supabase.from('deals').select('*'),
  supabase.from('calls').select('*'),
  supabase.from('users').select('*'),
]);
```

---

## Error Handling Pattern

Supabase returns `{ data, error }` — it does NOT throw. Check `error` on each result.

```tsx
// GOOD - explicit error check per query
const { data, error } = await supabase.from('deals').select('*');
if (error) throw new Error(`Failed to fetch deals: ${error.message}`);

// BAD - assumes success
const { data } = await supabase.from('deals').select('*');
data.forEach(...) // crashes if data is null due to error
```

---

## Supabase Client Setup

See the **supabase** skill for full client configuration. Summary:

```tsx
// lib/supabase/client.ts
import { createBrowserClient } from '@supabase/ssr';
import type { Database } from '@/lib/database';

export function createClient() {
  return createBrowserClient<Database>(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      realtime: { params: { eventsPerSecond: 0 } }, // disable auto-realtime
    }
  );
}
```

Always use the `Database` generic for full type safety. Generate types with `mcp__supabase__generate_typescript_types`.

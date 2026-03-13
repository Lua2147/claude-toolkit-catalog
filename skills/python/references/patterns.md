# Python Patterns Reference

## Contents
- Idiomatic patterns
- Async vs sync decisions
- Rate limiting
- Early returns / guard clauses
- Anti-patterns

---

## Idiomatic Patterns

### Keyword-only arguments for any function with 3+ parameters

```python
# GOOD — callers can't accidentally swap positional args
def search_people(
    *,
    keywords: str | None = None,
    titles: list[str] | None = None,
    limit: int = 100,
    open_profiles_only: bool = True,
) -> list[Lead]:
    ...

# BAD — easy to call as search_people("CEO", None, 50, False) and get wrong result
def search_people(keywords, titles, limit, open_profiles_only):
    ...
```

### Early returns over nested conditionals

```python
# GOOD — flat, readable
def run(campaign: CampaignConfig) -> list[Lead]:
    leads = unipile.search_people(...)
    if not leads:
        return []

    excluded = supabase_client.get_excluded_urls(client)
    filtered = [l for l in leads if l.linkedin_url not in excluded]
    if not filtered:
        logger.info("All leads excluded")
        return []

    return filtered

# BAD — deeply nested, harder to trace
def run(campaign):
    leads = unipile.search_people(...)
    if leads:
        excluded = ...
        result = []
        for lead in leads:
            if lead.linkedin_url not in excluded:
                result.append(lead)
        return result
    return []
```

### Set for membership testing, not list

```python
# GOOD — O(1) lookup
excluded: set[str] = {r["linkedin_url"] for r in result.data}
if lead.linkedin_url in excluded:
    continue

# BAD — O(n) for every check
excluded: list[str] = [r["linkedin_url"] for r in result.data]
if lead.linkedin_url in excluded:  # scans entire list every time
    continue
```

### Structured logging, never print

```python
import logging
logger = logging.getLogger(__name__)

# GOOD — filterable, with context
logger.info("Search returned %d leads (%d open profiles)", len(leads), open_count)
logger.error("API call failed: HTTP %s — %s", resp.status_code, resp.text[:200])

# BAD — lost in prod, no log level, no context
print(f"Got {len(leads)} leads")
```

---

## Async vs Sync Decision

All existing pipeline scripts are **synchronous** (`requests`, not `httpx`/`aiohttp`).
Only add async if:
- You need true parallelism across independent API calls
- The library requires it (e.g., Supabase realtime)

For CPU-bound or I/O bound work in a sync context, use `time.sleep()` for rate
limiting rather than `asyncio.sleep()`.

```python
# Correct rate limiting in sync code
for page in range(max_pages):
    resp = requests.post(url, json=body, timeout=30)
    process(resp)
    time.sleep(PAGE_DELAY)  # 1.0 second between SN pages
```

If you must use async, NEVER call blocking I/O from an async function:

```python
# WARNING: NEVER do this
async def fetch():
    time.sleep(1)  # blocks the event loop
    requests.get(url)  # blocking call in async context

# GOOD
async def fetch():
    await asyncio.sleep(1)
    async with httpx.AsyncClient() as client:
        return await client.get(url)
```

---

## Rate Limiting Pattern

Used in `scripts/utils/unipile.py` — replicate for any new API client:

```python
PAGE_DELAY = 1.0  # seconds between pages

while len(results) < limit:
    resp = requests.post(url, json=body, timeout=30)
    if resp.status_code == 429:
        retry_after = int(resp.headers.get("Retry-After", "60"))
        logger.warning("Rate limited, sleeping %ds", retry_after)
        time.sleep(retry_after)
        continue
    resp.raise_for_status()
    # ... process results
    if not cursor:
        break
    time.sleep(PAGE_DELAY)
```

---

## WARNING: Mutable Default Arguments

**The Problem:**

```python
# BAD — list shared across ALL calls
def add_lead(lead: Lead, results: list = []) -> list:
    results.append(lead)
    return results
```

**Why This Breaks:**
1. The list is created ONCE at function definition, not per call
2. Every call without an explicit `results` arg mutates the same object
3. State leaks between test cases, between pipeline runs

**The Fix:**

```python
# GOOD
def add_lead(lead: Lead, results: list[Lead] | None = None) -> list[Lead]:
    if results is None:
        results = []
    results.append(lead)
    return results

# Or more idiomatically with Pydantic — use Field(default_factory=list)
class Campaign(BaseModel):
    sender_accounts: list[str] = Field(default_factory=list)
```

---

## WARNING: Bare `except`

**The Problem:**

```python
# BAD — catches KeyboardInterrupt, SystemExit, everything
try:
    resp = requests.post(url, timeout=30)
except:
    pass
```

**Why This Breaks:**
1. Swallows `KeyboardInterrupt` — Ctrl+C doesn't work
2. Hides actual errors silently — pipeline appears to succeed
3. Impossible to debug in production

**The Fix:**

```python
# GOOD — specific, logged
try:
    resp = requests.post(url, timeout=30)
    resp.raise_for_status()
except requests.HTTPError as e:
    logger.error("API error: %s", e)
    return []
except requests.Timeout:
    logger.error("Request timed out after 30s")
    return []
```

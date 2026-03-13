# Python Error Handling Reference

## Contents
- HTTP error handling (requests)
- Supabase error handling
- Logging conventions
- Retry patterns
- Anti-patterns

---

## HTTP Error Handling (requests)

All HTTP calls must handle errors explicitly. Never silently swallow failures.

```python
import requests
import logging

logger = logging.getLogger(__name__)

def call_api(url: str, body: dict) -> dict | None:
    try:
        resp = requests.post(url, json=body, timeout=30)
    except requests.Timeout:
        logger.error("Request timed out: %s", url)
        return None
    except requests.ConnectionError as e:
        logger.error("Connection failed: %s — %s", url, e)
        return None

    if resp.status_code == 429:
        retry_after = int(resp.headers.get("Retry-After", "60"))
        logger.warning("Rate limited, retry after %ds", retry_after)
        return None  # caller handles retry

    if resp.status_code != 200:
        logger.error("API error HTTP %s: %s", resp.status_code, resp.text[:200])
        return None

    return resp.json()
```

**Log HTTP error bodies truncated** — `resp.text[:200]` — long bodies flood logs
and may contain PII.

---

## Supabase Error Handling

The supabase-py client raises `PostgrestAPIError` on query failures. It does NOT
raise on empty results — always check `result.data`:

```python
from supabase import Client
from postgrest.exceptions import APIError

def get_leads(client: Client, urls: list[str]) -> list[dict]:
    try:
        result = (
            client.table("linkedin_leads")
            .select("*")
            .in_("linkedin_url", urls)
            .execute()
        )
    except APIError as e:
        logger.error("Supabase query failed: %s", e)
        return []

    return result.data or []  # .data is None on empty results
```

**Common Supabase errors:**

| Scenario | Cause | Fix |
|----------|-------|-----|
| `APIError: JWT expired` | Service role key rotated | Update `config/api_keys.json` |
| `APIError: relation does not exist` | Wrong project URL | Check `SUPABASE_URL` in config |
| `result.data` is `None` | No rows matched | Always use `result.data or []` |
| upsert returns 0 rows | `ignore_duplicates=True` on existing | Expected — not an error |

---

## Logging Conventions

```python
import logging

# Module-level — always this exact pattern
logger = logging.getLogger(__name__)

# Structured with format args — NEVER f-strings (lazy evaluation = no cost if filtered)
logger.debug("Processing item: %s", item_id)
logger.info("Search complete: %d leads across %d pages", len(leads), pages_fetched)
logger.warning("Rate limited, sleeping %ds", retry_after)
logger.error("API call failed: HTTP %s — %s", resp.status_code, resp.text[:200])
logger.exception("Unexpected error in search agent")  # includes traceback
```

**Log level guidelines:**
- `debug` — per-item processing, API response details
- `info` — phase completions, counts, key milestones
- `warning` — recoverable issues (rate limits, retries, empty results)
- `error` — failures that produce no output but don't crash the pipeline
- `exception` — unexpected errors (use in `except` blocks to capture traceback)

---

## Retry Pattern (exponential backoff)

Use for transient 429/5xx errors. Don't retry 4xx client errors:

```python
import time

def with_retry(fn, max_retries: int = 3, base_delay: float = 2.0):
    for attempt in range(max_retries):
        result = fn()
        if result is not None:
            return result
        if attempt < max_retries - 1:
            delay = base_delay * (2 ** attempt)
            logger.warning("Attempt %d failed, retrying in %.1fs", attempt + 1, delay)
            time.sleep(delay)
    logger.error("All %d retries exhausted", max_retries)
    return None
```

---

## WARNING: Silent `except Exception: pass`

**The Problem:**

```python
# BAD — pipeline silently produces no output
try:
    leads = unipile.search_people(...)
    supabase_client.upsert_leads(client, leads)
except Exception:
    pass
```

**Why This Breaks:**
1. You get 0 leads with no indication of why
2. Monitoring/alerting never triggers
3. Debugging requires adding logging after the fact

**The Fix:**

```python
# GOOD — log and decide: reraise, return empty, or let it crash
try:
    leads = unipile.search_people(...)
except Exception as e:
    logger.exception("Search failed for campaign %s: %s", campaign.name, e)
    return []  # or: raise  — depends on whether callers can handle failure
```

**Decision rule:**
- Reraise (`raise`) if the failure should abort the entire pipeline
- Return empty/None if downstream code handles empty gracefully
- NEVER silently swallow

---

## WARNING: Using Global State for Error Tracking

**The Problem:**

```python
# BAD — global error flag breaks with concurrent agents
error_count = 0

def process(lead):
    global error_count
    try:
        ...
    except Exception:
        error_count += 1
```

**The Fix:**

```python
# GOOD — return results from functions, accumulate at call site
def process(lead: Lead) -> Lead | None:
    try:
        ...
        return lead
    except Exception as e:
        logger.error("Failed to process %s: %s", lead.linkedin_url, e)
        return None

results = [r for r in (process(l) for l in leads) if r is not None]
error_count = len(leads) - len(results)
logger.info("Processed %d/%d leads (%d errors)", len(results), len(leads), error_count)
```

---

## Checklist: Adding a New API Client

Copy this checklist when writing a new API integration:

- [ ] Specific exception types caught (not bare `except`)
- [ ] HTTP status checked before parsing JSON
- [ ] 429 handled with `Retry-After` header
- [ ] Timeout set on all requests (30s default)
- [ ] Errors logged with `logger.error` (not `print`)
- [ ] Return `None` or `[]` on failure — not empty Pydantic model
- [ ] Rate limit delay between pages (`time.sleep`)
- [ ] Response body truncated in logs (`resp.text[:200]`)

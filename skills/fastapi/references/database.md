# Database Reference

## Contents
- Database patterns in this project (DuckDB, SQLite, Supabase)
- Connection management
- Async vs sync
- Query patterns
- Anti-patterns

## Database Backends in This Project

| App | DB | Driver |
|-----|-----|--------|
| email-verifier | DuckDB | `duckdb` (sync) |
| beifong (resource) | SQLite | `aiosqlite` (async) |
| kadenwood | Supabase/Postgres | `supabase-py` |
| deal-origination | Supabase | `supabase-py` |

For Supabase patterns, see the **supabase** skill.

## DuckDB in FastAPI (KadenVerify pattern)

DuckDB is synchronous — use `asyncio.to_thread` if you need non-blocking, or accept that cache reads are fast enough to run on the event loop.

```python
# server.py — module-level singleton with lazy init
_cache_db = None

def _get_cache_db():
    global _cache_db
    if _cache_db is None:
        import duckdb
        cache_path = Path(__file__).parent / "verified.duckdb"
        _cache_db = duckdb.connect(str(cache_path))
        _cache_db.execute("""
            CREATE TABLE IF NOT EXISTS verified_emails (
                email VARCHAR PRIMARY KEY,
                reachability VARCHAR,
                verified_at TIMESTAMP
            )
        """)
    return _cache_db

def cache_lookup(email: str) -> VerificationResult | None:
    db = _get_cache_db()
    if not db:
        return None
    row = db.execute("SELECT * FROM verified_emails WHERE email = ?", [email]).fetchone()
    return VerificationResult(*row) if row else None
```

### DuckDB: commit + checkpoint

DuckDB uses WAL (Write-Ahead Log). Always call `commit()` after writes, and checkpoint periodically to keep WAL size under control.

```python
_update_count = 0

def cache_update(result: VerificationResult):
    global _update_count
    db = _get_cache_db()
    db.execute("INSERT OR REPLACE INTO verified_emails VALUES (?, ?, ?)", [...])
    db.commit()  # explicit commit required

    _update_count += 1
    if _update_count % 100 == 0:
        db.execute("CHECKPOINT")  # shrink WAL every 100 writes
```

## Async SQLite (aiosqlite pattern)

```python
import aiosqlite

class DatabaseService:
    def __init__(self, db_path: str):
        self.db_path = db_path

    async def execute_query(self, query: str, params=(), fetch=False, fetch_one=False):
        async with aiosqlite.connect(self.db_path) as db:
            db.row_factory = aiosqlite.Row
            async with db.execute(query, params) as cursor:
                if fetch:
                    if fetch_one:
                        row = await cursor.fetchone()
                        return dict(row) if row else None
                    rows = await cursor.fetchall()
                    return [dict(row) for row in rows]
                await db.commit()
                return cursor.lastrowid
```

## N+1 Prevention

```python
# BAD — N+1: fetches task name for each execution row
for execution in executions:
    task = await db.fetch_one("SELECT name FROM tasks WHERE id = ?", (execution["task_id"],))
    execution["task_name"] = task["name"]

# GOOD — JOIN once
executions = await db.fetch_all("""
    SELECT e.*, t.name as task_name
    FROM task_executions e
    LEFT JOIN tasks t ON t.id = e.task_id
    ORDER BY e.start_time DESC
    LIMIT ? OFFSET ?
""", (per_page, offset))
```

## WARNING: Global mutable DB state

**The Problem:**

```python
# BAD — _cache_db is None at startup, initialized lazily on first request
# If two concurrent requests both see _cache_db is None, both try to init
_cache_db = None

def _get_cache_db():
    global _cache_db
    if _cache_db is None:
        _cache_db = duckdb.connect(...)  # race condition on first concurrent requests
```

**The Fix:** Use FastAPI's lifespan to initialize DB once at startup:

```python
from contextlib import asynccontextmanager

@asynccontextmanager
async def lifespan(app: FastAPI):
    # startup
    app.state.db = init_db()
    yield
    # shutdown
    app.state.db.close()

app = FastAPI(lifespan=lifespan)

# In routes:
@app.get("/verify")
async def verify(request: Request):
    db = request.app.state.db
```

## WARNING: Sync blocking in async handler

**The Problem:**

```python
# BAD — duckdb.connect() and .execute() are synchronous
# Calling them directly in an async handler blocks the event loop
@app.get("/verify")
async def verify(email: str = Query(...)):
    db = duckdb.connect("cache.duckdb")       # blocks
    result = db.execute("SELECT ...", [email]) # blocks
    return result.fetchone()
```

**The Fix:** For fast cache lookups, the sync overhead is acceptable. For slow queries (>5ms), offload:

```python
import asyncio

@app.get("/verify")
async def verify(email: str = Query(...)):
    result = await asyncio.to_thread(cache_lookup, email)
    return result
```

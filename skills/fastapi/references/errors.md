# Errors Reference

## Contents
- HTTPException patterns
- Custom exception handlers
- Validation errors
- Error response shapes
- Testing errors
- Anti-patterns

## HTTPException

The standard way to return error responses in FastAPI.

```python
from fastapi import HTTPException

# 404 Not found
raise HTTPException(status_code=404, detail="Task not found")

# 400 Bad request
raise HTTPException(status_code=400, detail=f"Max batch size is {MAX_BATCH_SIZE}")

# 409 Conflict
raise HTTPException(
    status_code=409,
    detail=f"Task type '{task_type}' already exists (ID: {existing['id']})"
)

# 429 Rate limited
raise HTTPException(status_code=429, detail="Rate limit exceeded")

# 401 Unauthorized
raise HTTPException(status_code=401, detail="Invalid API key")
```

FastAPI serializes `detail` as JSON: `{"detail": "message"}`.

## Global Exception Handler

Catch unexpected exceptions before they leak stack traces to clients.

```python
from fastapi import Request
from fastapi.responses import JSONResponse
import logging

logger = logging.getLogger(__name__)

@app.exception_handler(Exception)
async def unhandled_exception_handler(request: Request, exc: Exception):
    logger.error(f"Unhandled error on {request.url}: {exc}", exc_info=True)
    return JSONResponse(
        status_code=500,
        content={"detail": "Internal server error"},
    )
```

NEVER return `str(exc)` in production responses — stack traces and internal state leak info to attackers.

## Validation Error Handling

FastAPI automatically returns 422 for Pydantic validation failures. Customize the response shape if your API consumers expect a different format:

```python
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse

@app.exception_handler(RequestValidationError)
async def validation_exception_handler(request: Request, exc: RequestValidationError):
    return JSONResponse(
        status_code=400,
        content={
            "detail": "Validation error",
            "errors": [
                {"field": ".".join(str(l) for l in e["loc"]), "msg": e["msg"]}
                for e in exc.errors()
            ],
        },
    )
```

## Structured Error Responses

For APIs with multiple consumers, define a consistent error shape:

```python
from pydantic import BaseModel

class ErrorResponse(BaseModel):
    detail: str
    code: str | None = None

# Use in route
@app.get("/verify")
async def verify(email: str = Query(...)):
    if not is_valid_email_syntax(email):
        raise HTTPException(
            status_code=400,
            detail=ErrorResponse(detail="Invalid email syntax", code="INVALID_SYNTAX").model_dump(),
        )
```

## Service Layer: Re-raise HTTPException

Always check `isinstance(e, HTTPException)` before wrapping in a generic 500:

```python
async def get_task(self, task_id: int):
    try:
        task = await db.fetch_one("SELECT * FROM tasks WHERE id = ?", (task_id,))
        if not task:
            raise HTTPException(status_code=404, detail="Task not found")
        return task
    except Exception as e:
        if isinstance(e, HTTPException):
            raise  # preserve original status code and detail
        logger.error(f"DB error fetching task {task_id}: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=f"Error fetching task: {e}")
```

## Testing Error Cases

```python
from fastapi.testclient import TestClient

def test_batch_size_limit(monkeypatch):
    monkeypatch.setattr(server, "API_KEY", "key")
    monkeypatch.setattr(server, "MAX_BATCH_SIZE", 5)
    client = TestClient(server.app)

    too_many = {"emails": [f"x{i}@example.com" for i in range(6)]}
    resp = client.post("/verify/batch", json=too_many, headers={"X-API-Key": "key"})
    assert resp.status_code == 400
    assert "Max batch size" in resp.json()["detail"]

def test_rate_limit_429(monkeypatch):
    monkeypatch.setattr(server, "RATE_LIMIT_MAX", 1)
    server._rate_limit_store.clear()
    client = TestClient(server.app)

    client.get("/health")
    resp = client.get("/health")
    assert resp.status_code == 429
```

## WARNING: Leaking internal errors to clients

**The Problem:**

```python
# BAD — exposes DB schema, file paths, or stack frames
except Exception as e:
    raise HTTPException(status_code=500, detail=str(e))
    # detail: "relation 'tasks' does not exist\nLINE 1: SELECT * FROM tasks..."
```

**Why This Breaks:**
1. Reveals DB schema structure to attackers
2. May expose file paths or environment variables in stack traces
3. Violates the principle of information minimization

**The Fix:**

```python
# GOOD — log internally, return generic message externally
except Exception as e:
    logger.error(f"Error in get_task({task_id}): {e}", exc_info=True)
    raise HTTPException(status_code=500, detail="Internal server error")
```

## WARNING: Missing error handling in stats/health endpoints

Stats and health endpoints often skip error handling because they feel "safe". They're not — if the DB is down, they'll raise an unhandled exception.

```python
# BAD
@app.get("/stats")
async def stats():
    return get_stats(conn)  # crashes if DB is unavailable

# GOOD
@app.get("/stats")
async def stats():
    try:
        return get_stats(conn)
    except Exception as e:
        return {"error": str(e), "total": 0}

@app.get("/health")
async def health():
    checks = {}
    try:
        _get_cache_db().execute("SELECT 1")
        checks["cache_db"] = "ok"
    except Exception:
        checks["cache_db"] = "error"
    return {"status": "ok" if all(v == "ok" for v in checks.values()) else "degraded", "checks": checks}
```

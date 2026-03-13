# Auth Reference

## Contents
- API key auth via Depends
- Multi-header compatibility (OmniVerifier pattern)
- Rate limiting dependency
- Security patterns
- Anti-patterns

## API Key via Depends

The simplest auth pattern — a dependency that reads headers and raises 401.

```python
import os
from fastapi import Depends, HTTPException, Request

API_KEY = os.environ.get("KADENVERIFY_API_KEY", "")

async def verify_api_key(request: Request):
    if not API_KEY:
        return  # No auth configured — open access
    key = request.headers.get("X-API-Key", "")
    if key != API_KEY:
        raise HTTPException(status_code=401, detail="Invalid API key")

# Apply to route
@app.get("/stats", dependencies=[Depends(verify_api_key)])
async def stats():
    ...
```

## Multi-Header Compatibility (OmniVerifier pattern)

When providing a drop-in replacement for another API, support all their auth header variants:

```python
async def verify_api_key_compat(request: Request):
    """Accepts X-API-Key, x-api-key, or Authorization: Bearer."""
    if not API_KEY:
        return
    key = (
        request.headers.get("X-API-Key", "")
        or request.headers.get("x-api-key", "")
    )
    if not key:
        auth = request.headers.get("Authorization", "")
        if auth.startswith("Bearer "):
            key = auth[7:]
    if key != API_KEY:
        raise HTTPException(status_code=401, detail="Invalid API key")
```

## Rate Limiting Dependency

In-memory sliding window rate limiter. Works for single-process deployments. For multi-process (gunicorn workers), use Redis.

```python
import time

_rate_limit_store: dict[str, list[float]] = {}
RATE_LIMIT_WINDOW = 60  # seconds
RATE_LIMIT_MAX = 100

async def check_rate_limit(request: Request):
    client_ip = request.client.host if request.client else "unknown"
    now = time.time()

    if client_ip not in _rate_limit_store:
        _rate_limit_store[client_ip] = []

    # Evict expired entries
    _rate_limit_store[client_ip] = [
        t for t in _rate_limit_store[client_ip]
        if now - t < RATE_LIMIT_WINDOW
    ]

    if len(_rate_limit_store[client_ip]) >= RATE_LIMIT_MAX:
        raise HTTPException(status_code=429, detail="Rate limit exceeded")

    _rate_limit_store[client_ip].append(now)
```

## Applying Multiple Dependencies

```python
# Both checked before handler executes
@app.get("/verify", dependencies=[Depends(verify_api_key), Depends(check_rate_limit)])
async def verify_single(email: str = Query(...)):
    ...

# Open endpoint — no auth
@app.get("/health")
async def health():
    return {"status": "ok"}

# Using security scheme for OpenAPI docs
from fastapi.security import APIKeyHeader

api_key_header = APIKeyHeader(name="X-API-Key", auto_error=False)

async def get_api_key(api_key: str | None = Depends(api_key_header)):
    if not API_KEY:
        return None
    if api_key != API_KEY:
        raise HTTPException(status_code=401, detail="Invalid API key")
    return api_key
```

## WARNING: Skipping auth on production routes

**The Problem:**

```python
# BAD — no auth on /stats, exposes internal metrics
@app.get("/stats")
async def stats_endpoint():
    return get_stats(conn)
```

**The Fix:** Every non-public route gets `dependencies=[Depends(verify_api_key)]`.

## WARNING: Hardcoded secrets

**The Problem:**

```python
# BAD
API_KEY = "my-secret-key-1234"
```

**The Fix:**

```python
# GOOD — from environment, no default in production
API_KEY = os.environ.get("KADENVERIFY_API_KEY", "")
# If empty, auth is skipped (dev convenience) — document this behavior
```

## WARNING: In-memory rate limiter with multiple workers

**The Problem:** If you run `uvicorn --workers 4`, each worker has its own `_rate_limit_store`. A client can make 100 req/min × 4 workers = 400 effective requests/min.

**The Fix:** Use Redis for shared state, or stick to single-worker deployment for internal services. KadenVerify runs single-worker on mundi-ralph — this is fine.

## Testing Auth

```python
from fastapi.testclient import TestClient
import server

def test_auth_header_compatibility(monkeypatch):
    monkeypatch.setattr(server, "API_KEY", "test-secret")
    client = TestClient(server.app)

    assert client.get("/v1/validate/foo@bar.com", headers={"X-API-Key": "test-secret"}).status_code == 200
    assert client.get("/v1/validate/foo@bar.com", headers={"x-api-key": "test-secret"}).status_code == 200
    assert client.get("/v1/validate/foo@bar.com", headers={"Authorization": "Bearer test-secret"}).status_code == 200
    assert client.get("/v1/validate/foo@bar.com", headers={"X-API-Key": "wrong"}).status_code == 401
```

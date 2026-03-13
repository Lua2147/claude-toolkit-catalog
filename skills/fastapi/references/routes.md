# Routes Reference

## Contents
- Route registration patterns
- Query/path params
- Response models
- Registration order trap
- Anti-patterns

## Route Registration Patterns

### Flat app (KadenVerify pattern)

```python
from fastapi import FastAPI, Depends, Query, HTTPException
from fastapi.responses import JSONResponse

app = FastAPI(title="KadenVerify", version="0.1.0")

@app.get("/verify", dependencies=[Depends(verify_api_key), Depends(check_rate_limit)])
async def verify_single(email: str = Query(..., description="Email address to verify")):
    result, tier, reason = await verify_email_tiered(email=email, ...)
    response = result.to_omniverifier()
    response["_kadenverify_tier"] = tier
    return response

@app.get("/health")
async def health():
    return {"status": "ok", "service": "kadenverify", "version": "0.1.0"}
```

### Router-based (multi-resource apps)

```python
# routers/tasks.py
router = APIRouter()

@router.get("/", response_model=List[Task])
async def get_tasks(include_disabled: bool = Query(False)):
    return await task_service.get_tasks(include_disabled=include_disabled)

@router.get("/stats", response_model=TaskStats)
async def get_task_stats():
    return await task_service.get_stats()

@router.get("/{task_id}", response_model=Task)
async def get_task(task_id: int = Path(...)):
    return await task_service.get_task(task_id)

# main.py
app.include_router(router, prefix="/tasks", tags=["tasks"])
```

### Pagination pattern

```python
@router.get("/executions")
async def get_task_executions(
    task_id: Optional[int] = Query(None),
    page: int = Query(1, ge=1),
    per_page: int = Query(10, ge=1, le=100),
):
    return await task_service.get_task_executions(
        task_id=task_id, page=page, per_page=per_page
    )
```

## Query and Path Params

```python
# Required query param
email: str = Query(..., description="Email to verify")

# Optional with default
include_disabled: bool = Query(False, description="Include disabled tasks")

# Path param with validation
task_id: int = Path(..., description="The task ID", ge=1)

# Bounded query param
per_page: int = Query(10, ge=1, le=100, description="Max 100")
```

## Response Models

```python
from pydantic import BaseModel

class Task(BaseModel):
    id: int
    name: str
    enabled: bool
    created_at: datetime

# FastAPI validates AND serializes the return value against this model
@router.get("/{task_id}", response_model=Task)
async def get_task(task_id: int = Path(...)):
    return await task_service.get_task(task_id)
```

`response_model` strips fields not in the model — use this to avoid leaking internal fields.

## WARNING: Route Registration Order

**The Problem:**

```python
# BAD — wildcard registered before specific route
@app.get("/v1/validate/{email}")   # matches FIRST
@app.get("/v1/validate/credits")   # NEVER reached
```

**Why This Breaks:**
A request to `/v1/validate/credits` matches `{email}` with `email="credits"`. FastAPI uses first-match routing.

**The Fix:**

```python
# GOOD — specific before wildcard
@app.get("/v1/validate/credits")   # exact match registered first
@app.get("/v1/validate/{email}")   # wildcard comes after
```

## WARNING: Sync functions in async app

**The Problem:**

```python
# BAD — blocks the event loop for all concurrent requests
@app.get("/verify")
def verify_single(email: str = Query(...)):  # sync def, not async def
    return slow_smtp_check(email)            # blocks entire thread pool
```

**The Fix:**

```python
# GOOD — non-blocking
@app.get("/verify")
async def verify_single(email: str = Query(...)):
    return await async_smtp_check(email)

# If you MUST call sync code (e.g., blocking library):
import asyncio
@app.get("/verify")
async def verify_single(email: str = Query(...)):
    return await asyncio.to_thread(blocking_smtp_check, email)
```

## Checklist: Adding a New Route

Copy and track progress:
- [ ] `async def` handler (not `def`)
- [ ] Specific routes registered before wildcard routes
- [ ] `response_model` set for consistent serialization
- [ ] `dependencies=[Depends(verify_api_key)]` on protected routes
- [ ] Status code explicit for non-200 success (`status_code=status.HTTP_201_CREATED`)
- [ ] `TestClient` test added

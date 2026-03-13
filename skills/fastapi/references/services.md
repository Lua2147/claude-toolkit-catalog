# Services Reference

## Contents
- Service layer pattern
- CRUD service example
- Error handling in services
- Singleton pattern
- Anti-patterns

## Service Layer Pattern

Put all business logic in service classes. Routes should be thin — they validate input, call a service, return the result. This makes services independently testable without HTTP.

```python
# services/task_service.py
from fastapi import HTTPException

class TaskService:
    async def get_task(self, task_id: int) -> dict:
        task = await db.fetch_one("SELECT * FROM tasks WHERE id = ?", (task_id,))
        if not task:
            raise HTTPException(status_code=404, detail="Task not found")
        return task

    async def create_task(self, name: str, task_type: str, ...) -> dict:
        existing = await self.check_task_exists(task_type)
        if existing:
            raise HTTPException(
                status_code=409,
                detail=f"Task type '{task_type}' already exists (ID: {existing['id']})"
            )
        task_id = await db.execute(
            "INSERT INTO tasks (name, task_type) VALUES (?, ?)", (name, task_type)
        )
        return await self.get_task(task_id)

task_service = TaskService()  # module-level singleton
```

```python
# routers/tasks.py — route delegates entirely to service
@router.get("/{task_id}", response_model=Task)
async def get_task(task_id: int = Path(...)):
    return await task_service.get_task(task_id)
```

## Update with Allowed Fields

NEVER build dynamic UPDATE queries from raw user input — it enables SQL injection and field-stuffing attacks.

```python
# GOOD — whitelist allowed fields explicitly
async def update_task(self, task_id: int, updates: dict) -> dict:
    allowed_fields = ["name", "description", "frequency", "frequency_unit", "enabled"]
    set_clauses = []
    params = []
    for field, value in updates.items():
        if field in allowed_fields:
            set_clauses.append(f"{field} = ?")
            params.append(value)

    if not set_clauses:
        return await self.get_task(task_id)

    params.append(task_id)
    await db.execute(
        f"UPDATE tasks SET {', '.join(set_clauses)} WHERE id = ?",
        tuple(params)
    )
    return await self.get_task(task_id)
```

## Pagination in Services

```python
async def get_executions(self, task_id: int | None, page: int, per_page: int) -> dict:
    offset = (page - 1) * per_page
    total = await db.fetch_one("SELECT COUNT(*) as count FROM executions")
    rows = await db.fetch_all(
        "SELECT * FROM executions ORDER BY start_time DESC LIMIT ? OFFSET ?",
        (per_page, offset)
    )
    total_pages = (total["count"] + per_page - 1) // per_page
    return {
        "items": rows,
        "total": total["count"],
        "page": page,
        "total_pages": total_pages,
        "has_next": page < total_pages,
        "has_prev": page > 1,
    }
```

## WARNING: HTTPException swallowing

**The Problem:**

```python
# BAD — catches HTTPException, wraps it in a new 500
async def get_task(self, task_id: int):
    try:
        ...
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))  # swallows 404!
```

**Why This Breaks:**
If a nested service call raises `HTTPException(404)`, the outer try/except catches it and re-raises as 500. The client sees the wrong status code.

**The Fix:**

```python
# GOOD — re-raise HTTPException as-is
async def get_task(self, task_id: int):
    try:
        ...
    except Exception as e:
        if isinstance(e, HTTPException):
            raise  # propagate original status code
        raise HTTPException(status_code=500, detail=f"Error fetching task: {e}")
```

## WARNING: Business logic in routes

**The Problem:**

```python
# BAD — validation, DB calls, and conditionals all in the route handler
@router.post("/")
async def create_task(task_data: TaskCreate):
    existing = await db.fetch_one("SELECT * FROM tasks WHERE task_type = ?", (task_data.task_type,))
    if existing:
        raise HTTPException(status_code=409, detail="Already exists")
    task_id = await db.execute("INSERT INTO tasks ...", (...))
    return await db.fetch_one("SELECT * FROM tasks WHERE id = ?", (task_id,))
```

**Why This Breaks:**
Can't unit test without HTTP. Duplicates logic when called from multiple routes or background tasks.

**The Fix:** Move all logic into the service layer. Routes call one service method and return.

# Python Types Reference

## Contents
- Type annotation conventions
- Pydantic v2 models
- Enums
- Anti-patterns

---

## Type Annotation Conventions

Always include `from __future__ import annotations` as the first non-comment line.
This enables PEP 604 union syntax (`X | Y`) and forward references in all Python 3.9+.

```python
from __future__ import annotations

from typing import Any
```

**Use modern syntax everywhere:**

| Old (avoid) | New (use) |
|------------|-----------|
| `Optional[str]` | `str \| None` |
| `List[str]` | `list[str]` |
| `Dict[str, Any]` | `dict[str, Any]` |
| `Tuple[str, int]` | `tuple[str, int]` |
| `Union[str, int]` | `str \| int` |

---

## Pydantic v2 Models

All data models in this codebase use **Pydantic v2**. Key differences from v1:

```python
from pydantic import BaseModel, Field

class Lead(BaseModel):
    # Optional fields with None default
    id: str | None = None
    first_name: str | None = None

    # Required field (no default)
    linkedin_url: str

    # List with mutable default — ALWAYS use Field(default_factory=...)
    tags: list[str] = Field(default_factory=list)
    metadata: dict[str, Any] = Field(default_factory=dict)

    # Enum field with default
    source: LeadSource = LeadSource.MANUAL
```

### WARNING: Never use `[]` or `{}` as default values in Pydantic

```python
# BAD — Pydantic accepts this but it's a footgun
class Lead(BaseModel):
    tags: list[str] = []  # shared mutable default

# GOOD
class Lead(BaseModel):
    tags: list[str] = Field(default_factory=list)
```

### Model config (v2 syntax)

```python
class CampaignConfig(BaseModel):
    copy_config: CopyTemplate = Field(default_factory=CopyTemplate, alias="copy")

    # Required for alias + field name access
    model_config = {"populate_by_name": True}
```

### Serialization

```python
# Dump to dict (v2 API — NOT .dict())
lead.model_dump()
lead.model_dump(exclude_none=True)
lead.model_dump(mode="json")  # converts datetime → ISO string

# Dump enum values (for Supabase rows)
source_value = lead.source.value  # "unipile"

# JSON serializing with non-serializable types
json.dumps(search.model_dump(), default=str)
```

### Validation (v2 validators)

```python
from pydantic import field_validator, model_validator

class SearchCriteria(BaseModel):
    limit: int = 500

    @field_validator("limit")
    @classmethod
    def limit_must_be_positive(cls, v: int) -> int:
        if v <= 0:
            raise ValueError("limit must be > 0")
        return min(v, 2500)  # cap at SN daily limit
```

---

## Enums

Use `str, Enum` for all status/type enums — this makes them JSON-serializable
and Supabase-compatible without `.value`:

```python
from enum import Enum

class LeadSource(str, Enum):
    UNIPILE = "unipile"
    LINKEDIN_CLI = "linkedin-cli"
    MANUAL = "manual"

class LeadStatus(str, Enum):
    LOADED = "loaded"
    CONTACTED = "contacted"
    REPLIED = "replied"
```

**Why `str, Enum`:**
- `lead.source == "unipile"` works (no `.value` needed for comparisons)
- Serializes directly in JSON without a custom encoder
- Supabase accepts it directly in `.upsert()` rows

**Inserting enums to Supabase:**

```python
# Both work, but be explicit in upsert rows
row = {
    "source": lead.source.value,        # explicit string
    "status": campaign.status.value,    # explicit string
}
```

---

## WARNING: `is` for Value Comparison

**The Problem:**

```python
# BAD — only works by coincidence for small integers and interned strings
if lead.source is "unipile":   # SyntaxWarning in Python 3.8+
if count is 0:                  # Only works because CPython caches small ints
```

**Why This Breaks:**
1. `is` tests object identity, not equality
2. String interning is an implementation detail — breaks across Python versions
3. Linters will warn; mypy will error

**The Fix:**

```python
# GOOD — equality for values
if lead.source == LeadSource.UNIPILE:
if count == 0:

# GOOD — identity only for singletons
if lead.first_name is None:
if result is not None:
```

---

## Type Narrowing

```python
# Use isinstance for narrowing when types are ambiguous
positions = item.get("current_positions", [])
if positions and isinstance(positions, list):
    pos = positions[0]
    title = pos.get("role") or pos.get("title")

# Use assert for type narrowing in tests (never in production code)
assert isinstance(lead, Lead)
```

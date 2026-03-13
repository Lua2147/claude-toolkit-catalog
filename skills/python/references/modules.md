# Python Modules Reference

## Contents
- Project structure conventions
- Import patterns
- Config module pattern
- Package layout
- Anti-patterns

---

## Project Structure (linkedin-outbound example)

```
apps/deal-origination/linkedin-outbound/
├── scripts/
│   ├── __init__.py
│   ├── cli.py              — Click CLI entry point
│   ├── config.py           — Lazy API key loader + path constants
│   ├── models.py           — Pydantic models + enums (no imports from scripts/)
│   ├── search_agent.py     — Agent: Unipile search → Supabase
│   ├── loader_agent.py     — Agent: Supabase leads → HeyReach
│   ├── monitor_agent.py    — Agent: campaign health check
│   ├── reply_agent.py      — Agent: reply classification
│   └── utils/
│       ├── __init__.py
│       ├── unipile.py      — Unipile API client
│       ├── heyreach.py     — HeyReach API client
│       └── supabase_client.py — Supabase queries
├── tests/
│   ├── test_search.py
│   └── test_unipile.py
└── config/
    └── campaigns/*.yaml
```

**Key rules:**
- `models.py` has NO imports from other `scripts/` modules (prevents circular deps)
- `config.py` has NO imports from other `scripts/` modules
- `utils/` has imports from `scripts.config` and `scripts.models` only
- Agents import from `scripts.models`, `scripts.utils.*`, and `scripts.config`

---

## Config Module Pattern

The lazy `__getattr__` pattern avoids loading API keys at import time — critical
for testability (tests can mock before first access) and for avoiding startup
errors when the key file is missing:

```python
# scripts/config.py
from __future__ import annotations
import json
from pathlib import Path

MONOREPO_ROOT: Path = Path.home() / "Mundi Princeps"
_API_KEYS_PATH: Path = MONOREPO_ROOT / "config" / "api_keys.json"

_api_keys_cache: dict | None = None

def _load_api_keys() -> dict:
    global _api_keys_cache
    if _api_keys_cache is None:
        with open(_API_KEYS_PATH) as f:
            _api_keys_cache = json.load(f)
    return _api_keys_cache

_LAZY_KEYS: dict[str, tuple[str, ...]] = {
    "UNIPILE_API_KEY": ("unipile", "api_key"),
    "SUPABASE_URL": ("supabase", "data_enrichment", "url"),
}

def __getattr__(name: str) -> str | Path:
    if name in _LAZY_KEYS:
        return _get_key(*_LAZY_KEYS[name])
    raise AttributeError(f"module {__name__!r} has no attribute {name!r}")
```

**Usage in other modules:**
```python
from scripts import config
# Access triggers lazy load only when first used
headers = {"X-API-KEY": config.UNIPILE_API_KEY}
```

---

## Import Ordering

Follow isort/ruff defaults (enforced by PostToolUse hook):

```python
from __future__ import annotations  # always first

# 1. Standard library
import json
import logging
import time
from pathlib import Path
from typing import Any

# 2. Third-party
import requests
import yaml
from pydantic import BaseModel, Field
from supabase import Client, create_client

# 3. Local
from scripts import config
from scripts.models import Lead, LeadSource
```

---

## CLI Entry Points (Click)

```python
# scripts/cli.py
import click
from scripts import config
from scripts.models import CampaignConfig

@click.group()
def cli() -> None:
    """LinkedIn outbound campaign management."""

@cli.command()
@click.argument("campaign_yaml", type=click.Path(exists=True))
@click.option("--dry-run", is_flag=True, help="Skip writes")
def launch(campaign_yaml: str, dry_run: bool) -> None:
    """Full pipeline: search → load → activate."""
    campaign = config.load_campaign(campaign_yaml)
    ...
```

Run via: `python -m scripts.cli launch config/campaigns/e2e_test.yaml`

---

## WARNING: Circular Imports

**The Problem:**

```python
# models.py imports from config.py
from scripts import config  # config.py imports from models.py → circular

# config.py
from scripts.models import CampaignConfig  # circular!
```

**Why This Breaks:**
1. Python's import system partially initializes the module — attributes are missing
2. Results in `ImportError: cannot import name 'X' from partially initialized module`
3. Breaks test isolation — can't mock individual modules

**The Fix — dependency hierarchy:**
```
models.py       (no local imports)
config.py       (no local imports)
utils/*.py      (imports from models, config)
*_agent.py      (imports from models, config, utils)
cli.py          (imports from models, config, utils, agents)
```

If you need to use a type from another module only in annotations, use `TYPE_CHECKING`:

```python
from __future__ import annotations
from typing import TYPE_CHECKING

if TYPE_CHECKING:
    from scripts.models import Lead  # only for type hints, not at runtime
```

---

## YAML Config Loading

```python
import yaml
from scripts.models import CampaignConfig

def load_campaign(path: str | Path) -> CampaignConfig:
    p = Path(path)
    with open(p) as f:
        raw = yaml.safe_load(f)  # NEVER yaml.load()
    return CampaignConfig(**raw)

def list_campaigns() -> list[Path]:
    return sorted(CAMPAIGNS_DIR.glob("*.yaml"))
```

NEVER use `yaml.load(f)` — it executes arbitrary Python from YAML and is a
critical security vulnerability. `yaml.safe_load` always.

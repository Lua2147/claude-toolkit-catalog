All 5 files created. Here's what was generated:

**`.claude/skills/python/`**
- `SKILL.md` — Quick reference with the two core patterns from this codebase: the Pydantic model shape and the lazy `__getattr__` config loader
- `references/patterns.md` — Idiomatic patterns (keyword-only args, early returns, set membership, structured logging), async vs sync decision guide, rate limiting, and anti-patterns (mutable defaults, bare except)
- `references/types.md` — Pydantic v2 conventions, enum patterns with `str, Enum`, modern union syntax, and the `is` vs `==` anti-pattern
- `references/modules.md` — Project structure layout, import ordering, the config module pattern, Click CLI setup, and circular import prevention
- `references/errors.md` — HTTP error handling with `requests`, Supabase error handling, logging conventions, retry pattern, and a checklist for new API clients

All examples are drawn directly from the actual codebase (`unipile.py`, `models.py`, `config.py`, `supabase_client.py`).
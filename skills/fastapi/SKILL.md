All 6 files written. Here's what was created:

**`.claude/skills/fastapi/`**
- `SKILL.md` — quick start, key concepts, route registration order gotcha, links to references
- `references/routes.md` — route patterns, query/path params, response models, registration order trap, async enforcement
- `references/services.md` — service layer pattern, dynamic UPDATE whitelisting, pagination, HTTPException re-raise, business logic anti-pattern
- `references/database.md` — DuckDB patterns (this project's actual DB), commit/checkpoint, async SQLite, N+1 prevention, lifespan startup pattern
- `references/auth.md` — API key via Depends, multi-header compatibility (exact OmniVerifier pattern from KadenVerify), in-memory rate limiter, testing auth
- `references/errors.md` — HTTPException patterns, global exception handler, validation error customization, service layer re-raise, leaking internal errors anti-pattern

All examples are grounded in `apps/email-verifier/server.py` and the beifong resource app — no fabricated patterns.
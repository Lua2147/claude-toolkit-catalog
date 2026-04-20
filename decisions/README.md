# Decisions Log

Dated decisions about the Claude Code toolkit and configuration. Each entry documents a change that touches user settings, plugins, hooks, or workflow — so future sessions (and future humans) can see *what* was changed, *why*, and *how to reverse it* if needed.

## Format

`YYYY-MM-DD-<short-slug>.md` with frontmatter:
- `date`
- `decision` (one line)
- `affects` (list of surfaces: mac, achilles, toolkit-repo, monorepo, settings.json, memory)
- `reversible` (yes/no/hard)

Body:
- **Decision** — what changed
- **Rationale** — why
- **How to reverse** — concrete steps
- **Verification** — how to confirm it's applied everywhere it should be

## Index

- [2026-04-20 — context-mode plugin disabled](2026-04-20-context-mode-disabled.md)
- [2026-04-20 — dialogue-gate hooks removed](2026-04-20-dialogue-gate-removed.md)
- [2026-04-20 — google-workspace MCP deduplicated](2026-04-20-gws-dedup.md)
- [2026-04-20 — linkdrop 3 rewrites (council / karpathy / 0x-kaize)](2026-04-20-linkdrop-3-rewrites.md)
- [2026-04-20 — router-hub discovery fixes](2026-04-20-router-hub-fixes.md)
- [2026-04-20 — KB indexing hygiene (ghost dirs + orphan fixes + outputs index)](2026-04-20-kb-indexing-hygiene.md)

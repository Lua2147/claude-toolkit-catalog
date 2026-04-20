# 2026-04-20 — Phase A+B: Skill rebuild + router-hub fixes

## Context

20 empty skill directories existed at `~/.claude/skills/` (created by a prior R&D autoresearch session that didn't actually persist content). Registry count mismatch: 1086/1106. Router-hub relevance audit at 64%.

## Decision

1. **Rebuild 15 of 20 empty dirs as faithful, project-grounded skills** (the other 5 were truly fabricated with no recoverable intent — removed earlier in the session).
2. **Router-hub discovery hardening** — three fixes: router-first ordering, stop-word filter, kind-based tie-break + grouped output.
3. **Keep all skills indexed** per user standing rule ("I want to keep all tools - I just want them indexed properly").

## What was built

### 15 new skills in `~/.claude/skills/`

Orchestrators (8):
- `mundi-orch-deal-origination/` — thesis → screened targets → one-pagers → tracker
- `mundi-orch-intent-signal/` — scrape/classify/score/route intent signals
- `mundi-orch-investor-outreach/` — LP/GP outbound via HeyReach/Unipile
- `mundi-orch-counterparty-enrich/` — single-entity deep enrichment via PB+CapIQ+Perplexity
- `mundi-orch-board-materials/` — board deck + supporting docs generator
- `mundi-orch-multi-llm-consensus/` — N-model agreement scoring
- `mundi-orch-multi-llm-debate/` — N-model adversarial audit
- `mundi-orch-multi-llm-route/` — task → provider classifier

QMD/utility skills (6):
- `mundi-qmd-intent-tool-coverage/` — MCP tool ↔ intent bucket audit (PB+CapIQ pattern)
- `mundi-qmd-auth-refresh-hub/` — centralized re-auth for PB/CapIQ/Unipile cookies
- `mundi-qmd-secret-scan-precommit/` — git pre-commit secret scan
- `mundi-qmd-fp-check-install/` — fingerprint check before brew/pip/npm install
- `mundi-qmd-ssh-deploy-generalized/` — generalized `rsync + ssh` deploy pattern
- `mundi-qmd-lead-enricher-supabase-writer/` — enrichment-to-Supabase write pattern

Business (1):
- `saraev-economic-math/` — agency/automation unit economics (retainer pricing, margin sanity, break-even, token cost)

### Path corrections applied

Three skills had hallucinated filesystem references caught by ensemble audit:
- `mundi-orch-deal-origination`: `themes/*.yaml` → `deal-intent-signal-app/deal_intelligence/config/*.yaml`
- `mundi-orch-intent-signal`: `signals/*.yaml` → `deal-intent-signal-app/deal_intelligence/signal_engine/signals/*.yaml`
- `mundi-qmd-intent-tool-coverage`: non-existent `pb_intent_index.json` → `apps/pitchbook-mcp/src/catalog.py` INTENT_INDEX

### Router-hub fixes

`~/.claude/scripts/route.sh` wrapper + `~/.claude/skills/router-hub/scripts/route.sh` updated:
- **Router-first ordering** — query tokens scored against skill `name` + `description` with higher weight than body
- **Stop-word filter** — drops "the, a, and, to, for" before ranking
- **Kind-based tie-break** — when scores equal, prefer `skill` over `agent` over `command` (matches user's invocation pattern)

Audit result: 64% → 88% relevance on 5 test queries.

## Registry state

**Before**: 1086/1106 (20 empty dirs polluting)
**After**: 1101/1101 parity (20 empty dirs rebuilt or removed; 2 auto-excluded)

Rebuild: `~/.claude/scripts/build-registry.sh`

## Queued: Phase C + D + E

See `docs/plans/2026-04-20-toolkit-phase-cde.md` (31KB plan, self-contained for tmux-pane handoff session):
- **Phase C** — Extend build-registry.sh to walk plugin caches (`~/.claude/plugins/cache/**/SKILL.md`). Expected +215 skills → ~1320 total indexed.
- **Phase D** — Marker-based partial-write for build-toolkit-scout.sh so curated head survives auto-regens.
- **Phase E** — Sync to Achilles + commit + verify service health (`ss -ltn` for PB :8766, CapIQ :8768).

## Safety verified

- Zero deletions since `phase3-pre-flight` tag — `check-no-deletions.sh` passes.
- Secret-redaction regex passes on all 15 new skills.
- No GBrain/OpenClaw references.
- Achilles services undisturbed (no restart, no port changes).

## Open follow-up

- 13/15 new skills score <6/8 on density checker — narrative-heavy vs structural-dense tradeoff. Not blocking. Revisit post-Phase-E.
- `skills/blog-image-generator/SKILL.md` has pre-existing uncommitted changes unrelated to this work — Phase E git-add should scope narrowly.

## Cross-references

- Plan: `docs/plans/2026-04-20-toolkit-phase-cde.md`
- Memory checkpoint: `~/.claude/projects/-Users-mundiprinceps-Mundi-Princeps/memory/project_toolkit_phase_cde_handoff.md`
- Prior decisions: `2026-04-20-router-hub-fixes.md`, `2026-04-20-context-mode-disabled.md`, `2026-04-20-global-claude-md-trim.md`

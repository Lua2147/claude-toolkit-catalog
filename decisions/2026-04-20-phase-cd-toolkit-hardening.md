# 2026-04-20 — Phase C+D: Plugin-pack registry indexing + toolkit-scout concierge

## Context

Follow-up to `2026-04-20-phase-ab-skill-rebuild.md`. That session rebuilt 15 empty skills, deleted 5 duplicate empty dirs, and rebuilt the registry at 1101/1101 parity. Two higher-leverage problems remained:

1. **Plugin-pack skills were invisible to the router.** `build-registry.sh` walked only `~/.claude/skills/`. Installed plugin packs (apollo-pack, document-skills, financial-analysis, investment-banking, private-equity, pm-*, superpowers, ai-skills) live under `~/.claude/plugins/cache/<marketplace>/<plugin>/<version>/skills/` and never got indexed. Router-hub couldn't return `financial-analysis:lbo-model` or `private-equity:ic-memo` for obvious queries.
2. **Toolkit-scout was a phone book, not a concierge.** The auto-generated `SKILL.md` showed "`saraev-cc-*` — 182 items" with no description. User feedback: "it does a shallow pass, it doesn't really go through everything."

## Decision

**Phase C** — extend `build-registry.sh` with a `walk_plugin_skills()` function that walks `~/.claude/plugins/cache/` only (explicitly excluding `~/.claude/plugins/marketplaces/` — 3,365 upstream-template SKILL.md files that would flood the registry 15x). Version-dedupe by `(marketplace, plugin)` tuple, keeping newest-mtime version. Prefix skill names with `<plugin>:<name>` to avoid collisions.

**Phase D** — convert `toolkit-scout/SKILL.md` into a hybrid concierge:
- **Curated head** (hand-maintained): router-first rule, by-intent index (23 task→tool mappings), 21 workflow recipes covering Mundi's actual workflows, family descriptions with prose.
- **Auto-generated tail** (regen'd on every registry rebuild): counts, MCP list, family frequency tables.
- **Separator marker**: `<!-- AUTO-GENERATED BELOW — DO NOT EDIT MANUALLY — run ~/.claude/scripts/build-toolkit-scout.sh to regenerate -->`. Build script aborts if 2+ markers found; preserves head byte-for-byte on regen.

## What changed

### `~/.claude/scripts/build-registry.sh`
- New `walk_plugin_skills()` helper, called after `walk_skills()` in main.
- Two-pass algorithm: group by `(marketplace, plugin)`, pick newest-mtime version, index only skills under that version.
- `source` field points to plugin version root (e.g. `~/.claude/plugins/cache/financial-services-plugins/financial-analysis/0.1.0`).
- `PLUGINS_CACHE_DIR` added to mtime-tracking so `generated_at` reflects plugin cache changes.

### `~/.claude/scripts/build-toolkit-scout.sh`
- Complete rewrite. Old version: `out.write_text(lines)` overwrote unconditionally.
- New version: marker-aware read-split-rejoin. 0 markers → write full template with default head. 1 marker → preserve head, replace only tail. 2+ markers → abort with error.
- Default curated head (used only when file is brand-new or has 0 markers) embeds the item count and router-first pointer.

### `~/.claude/skills/toolkit-scout/SKILL.md`
- Full rewrite with curated concierge head: router-first rule, by-intent map (23 categories), 21 recipes (counterparty enrichment, deal origination, IC memos, board materials, auth refresh, MCP deploy, investor outreach, intent signals, multi-LLM deliberation, LinkedIn outreach, Supabase queries, Playwright debug, ship, CLAUDE.md audit, PRD, landing page, secret scan, lead enrichment, MCP onboarding, session lookup, link-drop), rich family descriptions table, when-stuck flowchart, maintenance section.
- Auto-tail preserved via marker.

### `~/.claude/skills/mundi-qmd-secret-scan-precommit/SKILL.md`
- Minor security-doc fix: the example "intentional test payload" string literally matched its own regex, so Phase E's pre-sync secret scan flagged it. Replaced with a regex-safe placeholder (`AIza${FAKE_TEST_PAYLOAD_SUBSTITUTE_AT_RUNTIME}`). Pedagogy retained, self-collision resolved.

## Metrics

### Registry growth (Phase C)

| Kind | Before | After | Delta |
|---|---|---|---|
| skill | 1101 | 1280 | +179 plugin-pack skills (after version-dedup) |
| agent | 171 | 171 | — |
| command | 344 | 344 | — |
| mcp | 16 | 16 | — |
| script | 204 | 204 | — |
| **total items** | **1836** | **2015** | **+179** |

Plugin packs indexed: apollo-pack (24), document-skills (17, newest-version), financial-analysis (13, combining both version pools via newest-mtime), investment-banking (11), private-equity (9), pm-product-discovery (18), pm-product-strategy (12), pm-execution (15), pm-market-research (7), pm-data-analytics (3), pm-go-to-market (6), pm-marketing-growth (5), pm-toolkit (4), superpowers (14), ai-skills (20), pair-programmer (1), context-mode (excluded — plugin disabled).

Count 1280 is well under the 1400 guard threshold — walker correctly scoped to cache, never touched marketplaces.

### Router-hub discovery (Phase C+D combined)

Re-ran the audit's failing queries. Plugin-pack skills now surface correctly:

| Query | Before Phase C | After Phase C | Notes |
|---|---|---|---|
| `write an IC memo for a deal` | missed `private-equity:ic-memo` (not indexed) | `private-equity:ic-memo` #1 at 0.5231 | ✅ top result |
| `LBO model` | missed `financial-analysis:lbo-model` | `financial-analysis:lbo-model` #1 at 1.0207 | ✅ top result |
| `generate a financial LBO model` | missed `financial-analysis:lbo-model` | `financial-analysis:lbo-model` #5 at 0.5207 | behind 4 generic `model`/`generate` hits — query-phrasing artifact, not indexing issue. `LBO model` (shorter) ranks correctly. |
| `Playwright test` | missed `playwright` skill | `playwright` #5 at 0.5500 | ✅ surfaces after `test-engineer` agent + playwright MCP |
| `debug a failing Playwright test` | saraev flood | flood demoted via tie-break, `playwright`/`mcp__playwright__*` reachable via `Playwright test` | mixed — semantic match still weak on phrased queries |

### Toolkit-scout hybrid layout (Phase D)

- Before: 170 auto-gen lines, raw counts, no guidance.
- After: 380 lines (228 curated + 152 auto-gen). Curated head has 23-entry intent index, 21 recipes, 27-row family description table.
- `build-toolkit-scout.sh` regeneration verified idempotent via `diff` on consecutive runs (zero-diff).
- Marker preserved byte-for-byte across regens.

## Sync state

### Mac (source of truth for this session)
- `~/.claude/scripts/build-registry.sh` — extended
- `~/.claude/scripts/build-toolkit-scout.sh` — rewritten
- `~/.claude/skills/toolkit-scout/SKILL.md` — curated head + auto tail
- `~/.claude/skills/mundi-qmd-secret-scan-precommit/SKILL.md` — test payload fix
- Registry at `~/.claude/registry.json` rebuilt to 2015 items / 1280 skills

### Achilles (synced via rsync after Mac verified)
- All above files rsync'd to `/home/mundi/.claude/`
- Registry rebuilt to 2029 items / 1289 skills (minor drift vs Mac — expected, Achilles has a few extras)
- Post-sync health check: `ss -ltn` confirms PitchBook :8766 + CapIQ :8768 both LISTEN

### toolkit-catalog repo
- All 15 Phase B skills (`mundi-orch-*`, `mundi-qmd-*`, `saraev-economic-math`) added
- `scripts/build-registry.sh` + `scripts/build-toolkit-scout.sh` updated
- `skills/toolkit-scout/SKILL.md` updated
- Pre-existing `blog-image-generator` key redaction committed separately (same session, earlier) before sweeping Phase B+C+D changes into the catalog commit

## Pre-flight guardrails (all passed)

- ✅ `check-no-deletions.sh` exit 0
- ✅ `check-secrets.sh` on all sync targets exit 0 (after resolving self-collision in `mundi-qmd-secret-scan-precommit`)
- ✅ `pre-rsync-achilles-grep.sh` exit 0 (WARN on pre-existing Achilles-side key in `research/SKILL.md` is legacy, not introduced by this session)

## Cross-refs

- Predecessor decision: `2026-04-20-phase-ab-skill-rebuild.md`
- Original plan: `docs/plans/2026-04-20-toolkit-phase-cde.md` (669 lines, amended at `401758b3` with 11 ensemble-review fixes)
- Memory: `~/.claude/projects/-Users-mundiprinceps-Mundi-Princeps/memory/feedback_toolkit_scout_concierge.md` (new — written this session)
- Router-hub: `~/.claude/skills/router-hub/SKILL.md`, `~/.claude/skills/router-hub/scripts/route.sh`

## Non-regression

- No deletions since `phase3-pre-flight` tag (guard passed).
- No secrets in any staged file.
- No CLAUDE.md / settings.json touched.
- No PB/CapIQ cookie work.
- Achilles services stayed up throughout.

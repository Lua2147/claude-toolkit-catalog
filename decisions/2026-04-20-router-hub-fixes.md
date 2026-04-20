---
date: 2026-04-20
decision: Fix router-hub discovery (route.sh wrapper + stop-word filter + tie-break + deeper grouping)
affects: [mac, achilles, toolkit-repo, scripts, skills]
reversible: yes (via git revert in toolkit-catalog)
---

# Router-hub discovery fixes

## Decision

Three independent fixes landed on both Mac + Achilles:

### 1. `~/.claude/scripts/route.sh` wrapper created

Real implementation lives at `~/.claude/skills/router-hub/scripts/route.sh`. Multiple docs (`toolkit-scout/SKILL.md`, `MEMORY.md`) advertised the stable path `~/.claude/scripts/route.sh` which did not exist. Fresh sessions citing the stable path failed silently.

New file at `~/.claude/scripts/route.sh` (6 lines):
```bash
#!/usr/bin/env bash
exec bash "${HOME}/.claude/skills/router-hub/scripts/route.sh" "$@"
```

### 2. Stop-word filter + kind-based tie-break in router-hub

Live-test of the audit's 5 failing queries revealed the real problem wasn't ties — it was *query noise*. Common English words ("run", "a", "against", "with") overlapped with many unrelated items and pushed canonical matches out of top-5.

Added to `~/.claude/skills/router-hub/scripts/route.sh`:

- **Stop-word filter** — 70+ common English words filtered from both query tokens and item tokens before scoring. Falls back to unfiltered if the whole query was stop words. Single-char tokens also filtered.
- **Tie-break priority** — within score ties, prefer MCPs (rank 0), then commands (1), agents (2), skills (3), scripts (4). Within the same kind, demote flood-family prefixes (saraev, ariz, tob, hassid, rodman, gstack, pm-*, apollo-pack) by +3 priority points. This pushes root-level canonical skills ahead of 500+ saraev-* variants when scores tie.

### 3. `build-toolkit-scout.sh` deeper grouping

Previously collapsed 523 `saraev-*` skills into one unnavigable row. Changed `split("-", 2)` logic so known big families (saraev, ariz, tob, hassid, linkdrop, mundi, gstack, rodman) group at depth 2:

- `saraev-cc-*` (182), `saraev-vibe-*` (83), `saraev-biz-*` (74), `saraev-infra-*` (69), `saraev-outbound-*` (49)
- `ariz-marketing-*` (7), `ariz-product-*` (5), `ariz-content-*` (4), etc.
- `linkdrop-x-*` (12)
- `hassid-claude-*` (6), `hassid-cc-*` (4)

Other prefixes stay at single-segment depth (`geo-*`, `expo-*`, `cloudflare-*`, `better-*`).

## Results — live-tested against 5 audit queries (before vs after)

| query | before | after |
|---|---|---|
| "run a postgres query against Kadenwood supabase" | 1/5 (no postgres/supabase in top 5) | **5/5** — supabase-postgres-best-practices, postgres-optimization, data-engineer, mcp:supabase, skill:supabase |
| "debug why a Playwright test is flaking" | 2/5 (saraev flood) | 3/5 — saraev testing skills + test-engineer agent + mcp/playwright |
| "scrape a LinkedIn profile for deal origination" | 4/5 | 4/5 — origination-run, lead-scraper, scrape-social, backend-engineer |
| "fix a failing CI pipeline in the monorepo" | 4/5 | **5/5** — test-fix, ci-pipeline, analyze-ci-failure, fix-pipeline, monorepo-tooling |
| "write a PRD for a new investor-outreach feature" | 5/5 | 5/5 — prd-generator, write-a-prd |

Average relevance went from ~64% to ~88%. Playwright is still the weakest — the real `playwright` skill doesn't crack top-5 because the denser saraev testing skills overlap more query words. Acceptable — the top hits are still useful (test-engineer agent + mcp/playwright).

## How to reverse

All 3 changes live in files tracked by `claude-toolkit-catalog` git:

```bash
cd "/Users/mundiprinceps/Mundi Princeps/tmp/claude-toolkit-catalog"
git log --oneline scripts/route.sh scripts/build-toolkit-scout.sh skills/router-hub/scripts/route.sh
# git checkout <prior-sha> -- <path>
```

Then rsync back to both machines and regenerate:
```bash
rsync -a scripts/*.sh ~/.claude/scripts/
rsync -a skills/router-hub/scripts/route.sh ~/.claude/skills/router-hub/scripts/
bash ~/.claude/scripts/build-toolkit-scout.sh
# Same on Achilles
```

## Verification

```bash
# route.sh wrapper exists and forwards
ls -la ~/.claude/scripts/route.sh                       # → regular file, 294B, executable
bash ~/.claude/scripts/route.sh "postgres" --top=1      # → returns at least one result

# Stop-word filter working
bash ~/.claude/scripts/route.sh "run a postgres query against Kadenwood supabase" --top=5 | python3 -c 'import json,sys; d=json.load(sys.stdin); print([r["name"] for r in d["results"]])'
# → supabase-postgres-best-practices, postgres-optimization, data-engineer, supabase (mcp), supabase (skill)

# Deeper grouping visible in toolkit-scout
grep "saraev-cc-\*\|saraev-vibe-\*\|saraev-biz-\*" ~/.claude/skills/toolkit-scout/SKILL.md
# → 3 separate rows (not one "saraev-*" row)

# Achilles parity
ssh achilles-mundi 'ls -la /home/mundi/.claude/scripts/route.sh && head -1 /home/mundi/.claude/skills/router-hub/scripts/route.sh'
```

## Related

- Audit: inline router-hub live-test 2026-04-20 (5 queries, scored 0-5 relevance).
- Other linkdrop skill rewrites from same session: `2026-04-20-linkdrop-3-rewrites.md`.
- Known limitation: pure keyword matching cannot handle semantic queries like "flaky test" → "playwright" without embedding-based search. Acceptable tradeoff for now.

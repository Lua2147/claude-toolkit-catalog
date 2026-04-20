---
name: mundi-orch-deal-origination
description: End-to-end deal-origination pipeline orchestrator — converts a thesis / sector / theme into screened targets with IC-ready one-pagers. Chain: thesis lock → PB screener → signal enrichment → scoring → counterparty-enrich fan-out → one-pager generation → deal-tracker append. Use when running origination sprints, building a pipeline for a specific theme, or refreshing an existing pipeline with new entrants.
allowed-tools: Read, Write, Edit, Bash, Task, Grep, Glob, mcp__pitchbook__*, mcp__supabase__*, mcp__gws__*, mcp__qmd__*
---

# Mundi Orch — Deal Origination

## Overview

The reusable orchestrator behind `/mundi:origination-run`. Takes a thesis (sector + stage + geography + signal mix) and produces a ranked pipeline of IC-ready deals, each with a one-pager and tracker entry.

Input: origination thesis (theme YAML under `apps/deal-origination/deal-intent-signal-app/deal_intelligence/config/` or `signal_engine/signals/`, or ad-hoc description)
Output: ranked list of deals + per-deal one-pagers + Google Sheets tracker row appended per deal

## When to use

- Running a new origination sprint on a specific theme (e.g., "climate-tech growth-stage N.A.")
- Refreshing an existing theme with last-90-day signals
- Re-scoring an existing pipeline against a new intent signal

Skip if:
- Just looking up one company — use `mundi-orch-counterparty-enrich` directly
- Need investor-side outreach not origination — use `mundi-orch-investor-outreach`

## Pipeline (9 steps)

```
[1] Thesis lock         → load YAML or ask user (sector, stage, geo, signals, size)
[2] PB screener         → pb_screen_companies / pb_screen_deals with thesis filters
[3] Signal enrich       → pb_signal_enrich per hit (advisor hired, debt maturing, mgmt change, no-deal-in-years)
[4] De-dup + filter     → drop already-in-tracker entries, out-of-box-size, failed-IC-recently
[5] Parallel enrich     → mundi-orch-counterparty-enrich per hit (semaphore=2 PB-safe)
[6] Score + rank        → composite signal_strength + fit_to_thesis + timing
[7] One-pager gen       → investment-banking:one-pager OR private-equity:screen-deal per top-N
[8] Tracker append      → gws: append row to "Deal Tracker" Sheet with deal_id + one-pager link + score
[9] Summary             → markdown digest with top 10 by score + gaps / observations
```

## I/O contract (MWP)

**state_reads:**
- `~/Mundi Princeps/apps/deal-origination/deal-intent-signal-app/deal_intelligence/config/*.yaml` — top-layer signal configs (e.g. `top_layer_signals_ma_debt.yaml`)
- `~/Mundi Princeps/apps/deal-origination/deal-intent-signal-app/deal_intelligence/signal_engine/signals/*.yaml` — signal definitions (universal_signals, ma_signals, trigger_signals)
- `~/Mundi Princeps/config/api_keys.json` — PB, CapIQ, Supabase
- Existing tracker Sheet (Google Drive) — dedupe source
- `~/.claude/projects/.../memory/project_signal_audit.md` — 94 themes / 1,640 signals inventory

**state_writes:**
- `apps/deal-origination/runs/<theme>-<YYYY-MM-DD>/` — run artifacts
  - `hits.json` — raw screener output
  - `enriched.json` — after mundi-orch-counterparty-enrich fan-out
  - `ranked.json` — with scores
  - `one-pagers/<deal_id>.md` — per-deal one-pagers
- Google Sheet: append N rows to "Deal Tracker"
- Optional: `mcp__supabase__execute_sql` insert into `deals` table

## Composition

| step | tool |
|---|---|
| thesis load | `Read` on YAML + validation (source: `deal-intent-signal-app/deal_intelligence/config/` or `signal_engine/signals/`) |
| screener | `mcp__pitchbook__pb_screen_companies`, `pb_screen_deals` |
| signal enrich | `mcp__pitchbook__pb_signal_enrich`, `pb_signal_advisor_hired`, `pb_signal_debt_maturing`, `pb_signal_management_changes`, `pb_signal_no_deal_in_years` |
| dedup | Read existing tracker via `mcp__gws__readSpreadsheet` |
| counterparty fan-out | `Skill(skill="mundi-orch-counterparty-enrich")` per hit (semaphore-capped) |
| scoring | inline Python or dedicated scoring skill |
| one-pager | `Skill(skill="investment-banking:one-pager")` OR `Skill(skill="private-equity:screen-deal")` |
| tracker append | `mcp__gws__appendSpreadsheetRows` |
| CRM write (opt) | `mcp__supabase__execute_sql` |

**Rate-limit + safety rules:**
- PB screener calls: respect 2-per-second, single session.
- Per-hit enrichment: **semaphore=2** strictly. Do not parallelize beyond this.
- Memory: `feedback_no_parallel_scraping.md` — account-ban protocol.
- On PB 401: hard-stop; `apps/pitchbook-mcp/scripts/refresh-pb-cookies.sh`; resume from last checkpoint.

## Failure modes

| failure | recovery |
|---|---|
| Thesis YAML invalid | halt; surface schema errors |
| PB screener returns 0 | log + surface broader thesis suggestion; do not proceed |
| Enrichment partial (some hits fail) | proceed with available; mark failed hits in output with `enrichment: "failed"` |
| Google Sheet append fails | write to local CSV fallback at `apps/deal-origination/runs/<theme>-<date>/tracker-append.csv` |

## Invocation

```bash
/mundi:origination-run deal_intelligence/config/top_layer_signals_ma_debt.yaml --depth=full
```

```python
Skill(skill="mundi-orch-deal-origination", {
  theme_yaml: "apps/deal-origination/deal-intent-signal-app/deal_intelligence/config/top_layer_signals_ma_debt.yaml",
  depth: "full" | "lean",
  top_n_one_pagers: 15,
  append_to_tracker: true
})
```

## Output contract

```json
{
  "run_id": "climate-tech-growth-na-2026-04-20",
  "theme": {...},
  "hits_count": 87,
  "enriched_count": 84,
  "ranked": [
    {"deal_id": "...", "name": "...", "score": 0.87, "signal_mix": [...], "one_pager_path": "..."}
  ],
  "tracker_rows_appended": 15,
  "gaps": ["3 hits failed PB enrichment", "2 one-pagers deferred"],
  "summary_md": "<path>"
}
```

## Cross-references

- **Paired slash command:** `~/.claude/commands/mundi/origination-run.md`
- **Sub-orchestrators:** `mundi-orch-counterparty-enrich`, `mundi-orch-intent-signal` (alternate entry)
- **Plugin skills invoked:** `investment-banking:one-pager`, `investment-banking:cim`, `investment-banking:teaser`, `private-equity:screen-deal`, `private-equity:ic-memo`
- **App context:** `apps/deal-origination/` (ETL pipelines, theme YAMLs), `apps/pitchbook-mcp/` (screener tools), `apps/investor-outreach-platform/` (downstream pipeline)
- **Memory:** `project_signal_audit.md`, `project_pb_phase1_*`, `feedback_pb_account_safety_protocol.md`
- **KB:** `docs/knowledge-base/wiki/03-intent-signal-and-origination/INDEX.md`
- **Plan source:** `docs/plans/2026-04-19-phase-3-final.md` line 866

## Safety

- Account safety dominates throughput. Prefer **1 solid run over 3 fast runs that burn an account**.
- Always checkpoint at step 5 — if the run crashes during enrichment, resume from `enriched.json`.
- Never write to the master deal tracker without dedupe step 4.

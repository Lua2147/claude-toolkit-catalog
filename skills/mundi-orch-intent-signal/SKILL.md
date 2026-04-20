---
name: mundi-orch-intent-signal
description: End-to-end intent-signal pipeline orchestrator — scrape/classify/score intent signals from web + PB + CapIQ, dedupe, and route to downstream (outreach, CRM, scoring). Use when monitoring a theme for new signals, ingesting a fresh signal batch, or wiring a signal → outreach handoff. Paired with /mundi:intent-signal-run.
allowed-tools: Read, Write, Edit, Bash, Task, Grep, Glob, mcp__pitchbook__*, mcp__perplexity__*, mcp__heyreach__*, mcp__supabase__*, mcp__qmd__*
---

# Mundi Orch — Intent Signal Pipeline

## Overview

The reusable orchestrator behind `/mundi:intent-signal-run`. Detects, classifies, scores, and routes intent signals for a theme — the deal-origination counterpart to a real-time "radar."

Input: signal YAML at `apps/deal-origination/deal-intent-signal-app/deal_intelligence/signal_engine/signals/*.yaml` (universal / MA / trigger) or `config/top_layer_signals_*.yaml` (memory inventory via project_signal_audit.md tracks the broader catalog)
Output: ranked signals with evidence + routing decisions (enrich? outreach? CRM log? drop?)

## When to use

- Running continuous intent-signal monitoring on an active theme
- Ingesting a signal batch from a scrape / Perplexity research run
- Wiring signal-detection → counterparty-enrich → outreach as a single pipeline
- Validating a new signal type before adding it to the theme YAML catalog

## Pipeline (8 steps)

```
[1] Load signal YAML    → apps/deal-origination/deal-intent-signal-app/deal_intelligence/signal_engine/signals/*.yaml OR config/top_layer_signals_*.yaml
[2] Signal fan-out      → pb_signal_* (advisor hired, debt maturing, mgmt change, no-deal-in-years, fund-exits-due)
[3] Web grounding       → perplexity_research for each signal hit (recent news, filings, press)
[4] Classify + score    → evidence keywords (8+), regex patterns (3+), timeline, sources → 0-100 score
[5] Dedupe              → against CRM + last-N-day signal log
[6] Route decision      → score > threshold_A → enrich; > threshold_B → outreach; else log-only
[7] Downstream fan-out  → mundi-orch-counterparty-enrich OR mundi-orch-investor-outreach
[8] CRM log             → Supabase insert into signals table + Google Sheet append
```

## I/O contract (MWP)

**state_reads:**
- `apps/deal-origination/deal-intent-signal-app/deal_intelligence/signal_engine/signals/{universal,ma,trigger}_signals.yaml` — live signal definitions
- `apps/deal-origination/deal-intent-signal-app/deal_intelligence/config/top_layer_signals_*.yaml` — aggregate signal configs (e.g. `top_layer_signals_ma_debt.yaml`)
- `~/Mundi Princeps/config/api_keys.json` — PB, Perplexity, Supabase keys
- `~/.claude/projects/.../memory/project_signal_audit.md` — aspirational/tracked signal inventory (94 themes, 1640 signals — broader catalog not all on disk)
- `~/.claude/projects/.../memory/project_track05_session*.md` — track 0.5 enrichment patterns

**state_writes:**
- `apps/deal-origination/deal-intent-signal-app/deal_intelligence/output/signal-runs/<theme>-<date>/hits.json`
- `apps/deal-origination/deal-intent-signal-app/deal_intelligence/output/signal-runs/<theme>-<date>/scored.json`
- Supabase `signals` table row per high-score hit
- Optional: HeyReach list populate via `mcp__heyreach__add_leads_to_list_v2`
- Optional: Google Sheet append to Signal Tracker

## Composition

| step | tool |
|---|---|
| signal fan-out | `mcp__pitchbook__pb_signal_advisor_hired`, `pb_signal_debt_maturing`, `pb_signal_management_changes`, `pb_signal_no_deal_in_years`, `pb_signal_fund_exits_due`, `pb_signal_enrich` |
| web grounding | `mcp__perplexity__perplexity_research` |
| classify | inline Python + regex lib per theme YAML |
| score | composite: evidence_keywords * 0.4 + regex_matches * 0.3 + timeline_recency * 0.2 + source_count * 0.1 |
| dedupe | `mcp__supabase__execute_sql` lookup |
| enrich downstream | `Skill(skill="mundi-orch-counterparty-enrich")` |
| outreach downstream | `Skill(skill="mundi-orch-investor-outreach")` OR HeyReach direct |
| log | `mcp__supabase__execute_sql` insert + `mcp__gws__appendSpreadsheetRows` |

## Safety + rate-limit rules

- PB signal tools: respect account semaphore=2.
- Perplexity: 30s per call; cap at 20 parallel.
- Score thresholds — defaults: enrich ≥70, outreach ≥85, drop <50. User-tunable per theme.
- Memory: `feedback_api_probing.md` — space out multi-endpoint calls (Inven flagged).

## Failure modes

| failure | recovery |
|---|---|
| Theme YAML missing keys | halt; surface schema errors; point at signal_audit.md for required shape |
| PB signal returns 0 | proceed; log "no signals this window" |
| Perplexity timeout on single hit | proceed; mark that hit "no web grounding" |
| Scoring under-coverage (<3 keyword matches) | include in output with `score_confidence: low` warning |

## Invocation

```bash
/mundi:intent-signal-run deal_intelligence/signal_engine/signals/ma_signals.yaml --route=enrich
```

```python
Skill(skill="mundi-orch-intent-signal", {
  theme_yaml: "apps/deal-origination/deal-intent-signal-app/deal_intelligence/signal_engine/signals/ma_signals.yaml",
  window_days: 30,
  route_high: "enrich+outreach",
  route_mid: "enrich",
  route_low: "log"
})
```

## Output contract

```json
{
  "run_id": "pe-exit-2026-q2-2026-04-20",
  "theme": {...},
  "signals_found": 42,
  "signals_scored_high": 7,
  "signals_scored_mid": 18,
  "signals_scored_low": 17,
  "routed_to_enrich": 25,
  "routed_to_outreach": 7,
  "dedupe_dropped": 5,
  "gaps": [...],
  "next_actions": ["run /mundi:counterparty-enrich on batch X", "review 7 outreach candidates"]
}
```

## Cross-references

- **Paired slash command:** `~/.claude/commands/mundi/intent-signal-run.md`
- **Live signal YAMLs:** `apps/deal-origination/deal-intent-signal-app/deal_intelligence/signal_engine/signals/{universal,ma,trigger}_signals.yaml` + `config/top_layer_signals_*.yaml`; broader aspirational catalog (94 themes, 1640 signals) tracked in `project_signal_audit.md`
- **Downstream:** `mundi-orch-counterparty-enrich`, `mundi-orch-investor-outreach`, HeyReach campaigns
- **Memory:** `project_signal_audit.md` (1640 signals / 94 themes), `project_track05_session1.md`, `project_track05_session3.md`
- **KB:** `docs/knowledge-base/wiki/03-intent-signal-and-origination/INDEX.md`
- **Plan source:** `docs/plans/2026-04-19-phase-3-final.md` line 869

## Safety

- Never route a signal to outreach without human review first run (dry-run mode).
- Dedupe is mandatory before any CRM write — prevents double-contact.
- Score thresholds are theme-specific; never use defaults without validating against theme YAML.

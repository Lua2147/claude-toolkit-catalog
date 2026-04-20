---
name: mundi-orch-counterparty-enrich
description: Reusable orchestrator that enriches a counterparty (company, investor, LP, advisor, or person) via entity resolution → parallel fan-out across PitchBook + CapIQ + A-Leads + Orbis + Perplexity → merged dossier with provenance. Use when you need a complete profile of a counterparty before outreach, IC discussion, or deal evaluation. Invoked by /mundi:counterparty-enrich and chained by /mundi:origination-run.
allowed-tools: Read, Write, Edit, Bash, Task, Grep, Glob, mcp__pitchbook__*, mcp__qmd__*, mcp__perplexity__*, mcp__supabase__*
---

# Mundi Orch — Counterparty Enrichment

## Overview

The canonical enrichment engine for counterparties in Mundi Princeps deal work. Paired with `/mundi:counterparty-enrich` as the user-facing slash command; this skill is the *reusable orchestrator* that other workflows (origination-run, intent-signal-run, investor-outreach) compose.

Input: a counterparty reference (name, PB id, LinkedIn URL, or free-text).
Output: normalized dossier with provenance per field + confidence score + outreach-ready contact data.

## When to use

- Pre-IC prep: need a full dossier on a target company / investor / LP
- Before outreach: confirm identity, map decision-makers, identify warm intros
- Deal-origination fan-out: enrich a list of screener hits into actionable prospects
- Reactivation: re-enrich a stale counterparty with fresh PB/CapIQ data

Do NOT use for:
- One-off "what is company X" lookups — use `mcp__pitchbook__pb_company` directly
- People-only queries with no company context — use `mcp__pitchbook__pb_person`

## Pipeline (7 steps)

```
[1] Entity resolve    → pb_entity_resolve + qmd previous-session lookup
[2] PitchBook fan-out → pb_company | pb_investor | pb_lp | pb_advisor | pb_person
[3] CapIQ enrich      → capiq search_companies / search_contacts / get_financial_periods
[4] Signal enrich     → pb_signal_enrich (advisor hired, debt maturing, mgmt change, etc.)
[5] A-Leads + Orbis   → contact-level enrichment (emails, phones, LinkedIn)
[6] Perplexity grounding → recent news, press releases, context the APIs miss
[7] Merge + provenance → each field tagged with source + timestamp + confidence
```

## I/O contract (MWP)

**state_reads:**
- `~/Mundi Princeps/config/api_keys.json` — LSEG, Orbis, A-Leads keys
- `~/Mundi Princeps/apps/deal-origination/` — active theme YAMLs (for scoring context)
- `~/.claude/projects/-Users-mundiprinceps-Mundi-Princeps/memory/project_pb_counterparty_v7_*.md` — prior-wave patterns

**state_writes:**
- `apps/pitchbook-mcp/output/counterparty-<id>-<date>.json` — raw dossier
- `apps/pitchbook-mcp/output/counterparty-<id>-<date>.md` — human-readable one-pager
- Optional: `mcp__supabase__execute_sql` insert into `enriched_contacts` if writing-through to Kadenwood CRM

## Composition

| step | tool | rate-limit |
|---|---|---|
| entity resolve | `mcp__pitchbook__pb_entity_resolve` | PB account-safe (semaphore=2) |
| company | `mcp__pitchbook__pb_company` | same PB budget |
| investor | `mcp__pitchbook__pb_investor` | same |
| lp | `mcp__pitchbook__pb_lp` | same |
| advisor | `mcp__pitchbook__pb_advisor` | same |
| person | `mcp__pitchbook__pb_person` | same |
| signal | `mcp__pitchbook__pb_signal_enrich` | same |
| contact enrich | `mcp__pitchbook__pb_contact_enrichment` | same |
| capiq company | code path in `apps/capiq-mcp/src/tools/` | capiq account-safe |
| web context | `mcp__perplexity__perplexity_research` | 30s per call |
| prior-session | `mcp__qmd__deep_search` | free |
| write | `mcp__supabase__execute_sql` | Supabase rate limits |

**Critical rules:**
- PB + CapIQ parallelism cap: **semaphore=2 per provider**. See memory `feedback_no_parallel_scraping.md` — 9 parallel agents burned Account 1.
- If PB returns 401: hard-stop, trigger `apps/pitchbook-mcp/scripts/refresh-pb-cookies.sh`, do NOT retry in loop.
- CapIQ: respect pace-tracker circuit breaker in `apps/capiq-mcp/src/pace_tracker.py`.

## Failure modes

| failure | recovery |
|---|---|
| PB 401 on entity_resolve | stop; refresh cookies; resume from step 1 |
| CapIQ circuit-breaker open | skip step 3; log degraded-enrichment flag in dossier |
| Perplexity timeout | skip step 6; log "no web grounding" |
| A-Leads rate-limit | defer step 5 to end-of-queue; complete dossier without contact data |
| Entity not resolved | return "unresolved" status + surface top-3 PB candidates for human pick |

## Invocation

```bash
# Via slash command (user-facing)
/mundi:counterparty-enrich "Bessemer Venture Partners" --kind=investor

# Via direct Skill invocation (composed by other orchestrators)
Skill(skill="mundi-orch-counterparty-enrich", {
  entity: "Bessemer Venture Partners",
  kind: "investor",
  depth: "full" | "lean",
  write_crm: true
})
```

## Output contract

```json
{
  "entity": {"pb_id": "...", "name": "...", "kind": "investor"},
  "fields": {
    "<field>": {"value": "...", "source": "pb|capiq|perplexity|orbis", "confidence": 0.0-1.0, "fetched_at": "ISO8601"}
  },
  "signals": [{"type": "advisor_hired", "detail": "...", "date": "..."}],
  "contacts": [{"name": "...", "title": "...", "email": "...", "linkedin": "...", "source": "..."}],
  "warm_intros": [{"path": "[you → mutual → target]", "strength": 0.0-1.0}],
  "gaps": ["unresolved_domain", "no_web_grounding"],
  "one_pager_md": "<path to .md artifact>"
}
```

## Cross-references

- **Paired slash command:** `~/.claude/commands/mundi/counterparty-enrich.md`
- **Wraps:** `pitchbook-mcp` (v2.2.2, 224 tools on Achilles :8766), `capiq-mcp` (81 tools on :8768)
- **Called by:** `mundi-orch-deal-origination`, `mundi-orch-intent-signal`, `mundi-orch-investor-outreach`
- **Memory:** `project_pb_counterparty_v7_*` (11 waves of pattern work), `feedback_pb_account_safety_protocol.md`, `feedback_no_parallel_scraping.md`
- **KB:** `docs/knowledge-base/wiki/03-intent-signal-and-origination/INDEX.md`
- **Plan source:** `docs/plans/2026-04-19-phase-3-final.md` line 867 (Stream 2C)

## Safety

- **Account safety first.** PB + CapIQ sessions are finite. Respect semaphore, budget, cool-down. If in doubt, run lean mode (PB only).
- **Provenance required.** Every field in the dossier must have `source` + `fetched_at`. No provenance = not in dossier.
- **No speculation.** If a field can't be resolved, return `null` with `gap: "unresolved"`. Do not infer.

---
name: mundi-qmd-lead-enricher-supabase-writer
description: Runbook for wiring the lead-enricher's SupabaseWriter (112 lines, batch-of-100 inserts to enriched_contacts) into the enrichment waterfall as the terminal step, plus handling provider-swap away from PeopleDataLabs (100/month free cap blocks production). Use when shipping lead-enricher to production, scaling beyond free tier, or adding a new enrichment provider to the waterfall.
allowed-tools: Read, Write, Edit, Bash, Grep, Glob, mcp__supabase__*
---

# Mundi QMD — Lead-Enricher Supabase Writer Integration

## Overview

The `apps/lead-enricher/` stack has a `SupabaseWriter` class that's fully written and tested but **never wired into the production waterfall**. This skill codifies the wiring + the companion problem: PeopleDataLabs' free tier (100 enrichments/month) blocks production usage.

Two tasks this skill handles:
1. Wire `SupabaseWriter` into `waterfall.py` as the terminal step.
2. Swap or tier-up PDL for higher-volume provider.

## When to use

- Shipping lead-enricher from staging to production
- Scaling beyond the 100/month PDL cap
- Adding a new enrichment provider to the waterfall
- Debugging "enrichment runs but nothing in Supabase" (the exact bug this wiring fixes)

## Pre-existing implementation

- **`apps/lead-enricher/enrichment/supabase_writer.py`** — 112 lines, `SupabaseWriter` class
  - Batch inserts to `enriched_contacts` table
  - Batch size: 100 rows
  - Credentials: `config/api_keys.json["supabase"]["data_enrichment"]`
  - `_to_row(enrichment_result)` maps internal model → Supabase schema
- **`apps/lead-enricher/enrichment/waterfall.py`** — 10.6 KB — the integration point (currently missing terminal write)
- **`apps/lead-enricher/enrichment/models.py`** — `EnrichmentResult` shape
- **`apps/lead-enricher/providers/peopledatalabs.py`** — the provider being scaled past or replaced

## The wiring runbook

```
[1] Read waterfall.py — confirm enrichment results flow through (each provider returns EnrichmentResult)
[2] After the last provider success path, call writer.write_batch(results)
[3] Add writer as constructor dependency; default None for unit tests
[4] Schema verification: run mcp__supabase__list_tables to confirm enriched_contacts exists
[5] Dry-run mode: --dry-run flag → log rows but don't insert
[6] Production flag: --write-supabase (off by default)
[7] Test: enrich 10 contacts → verify 10 rows in Supabase
[8] Deploy: bump version, update apps/lead-enricher/CLAUDE.md with new waterfall sketch
```

## Provider swap for scale (PDL issue)

PeopleDataLabs free tier: 100 enrichments/month. Production needs 10-100k/month.

**Options ranked:**

1. **PDL paid tier** — $0.10-0.30/enrichment depending on volume. Simple swap (no code change, just key).
2. **Apollo.io** — already have keys; `apps/lead-enricher/providers/` has scaffold. ~$0.05/enrichment at volume.
3. **A-Leads** — key in `config/api_keys.json`; may need a new provider module in `apps/lead-enricher/providers/aleads.py`.
4. **Unipile** — LinkedIn-centric, not general enrichment. Fits profile scraping, not contact enrichment.
5. **Clearbit** — industry standard; most expensive; consider only if others miss.

**Recommendation:** try Apollo → A-Leads → PDL paid in that order. Waterfall pattern means each provider tries once; failure falls through.

## I/O contract (MWP)

**state_reads:**
- `~/Mundi Princeps/apps/lead-enricher/enrichment/supabase_writer.py` — existing implementation
- `~/Mundi Princeps/apps/lead-enricher/enrichment/waterfall.py` — integration point
- `~/Mundi Princeps/apps/lead-enricher/enrichment/models.py` — `EnrichmentResult`
- `~/Mundi Princeps/config/api_keys.json["supabase"]["data_enrichment"]`
- `~/Mundi Princeps/config/api_keys.json` — A-Leads, Apollo, PDL keys

**state_writes:**
- `apps/lead-enricher/enrichment/waterfall.py` (updated wiring)
- Supabase `enriched_contacts` rows (on live run)
- `apps/lead-enricher/CLAUDE.md` — refreshed waterfall diagram

## Schema (enriched_contacts)

From `supabase_writer._to_row`:
- `email` (primary), `first_name`, `last_name`, `title`, `company`, `linkedin_url`, `phone`, `location`, `seniority`
- `source` (provider name), `enrichment_confidence` (0-1), `enriched_at` (ISO8601)
- `raw_payload` (JSONB) — full provider response for audit
- `batch_id` (UUID) — group related enrichments

## Failure modes

| failure | recovery |
|---|---|
| `enriched_contacts` table doesn't exist | run migration at `apps/lead-enricher/migrations/<date>-create-enriched-contacts.sql` |
| Supabase service-role key expired | refresh via `mcp__supabase__*` or Vercel env |
| PDL 429 (rate limit) | fall through to next provider; don't retry same provider |
| PDL quota exhausted (100/month hit) | swap to Apollo; upgrade PDL if reason to stay |
| Supabase insert fails mid-batch | retry just the failed row; don't re-insert batch (dedup via email unique constraint) |
| Schema mismatch (new provider has fields writer doesn't know) | extend `_to_row`; add JSONB overflow to `raw_payload` |

## Invocation

```bash
# Production run
cd apps/lead-enricher
python -m enrichment.waterfall --input leads.csv --write-supabase

# Dry-run (safe)
python -m enrichment.waterfall --input leads.csv --dry-run

# Single contact test
python -m enrichment.waterfall --email example@co.com --write-supabase
```

## Cross-references

- **Implementations:** `apps/lead-enricher/enrichment/supabase_writer.py`, `waterfall.py`, `providers/peopledatalabs.py`, `providers/apollo.py` (if exists)
- **Memory:** `project_kadenverify_v2.md` (multi-agent email verification context), `state.md` (credentials + platform inventory)
- **Related skills:** `mundi-orch-investor-outreach` (downstream consumer), `mundi-qmd-auth-refresh-hub` (if provider auth expires)
- **KB:** `docs/knowledge-base/outputs/qmd-action-items-for-wave2.md` item #5
- **App docs:** `apps/lead-enricher/docs/CLAUDE.md`

## Safety

- **Always dry-run first.** Batch-insert 1000 bad rows is worse than none.
- **Unique email constraint required.** Prevents double-write if same lead enriched twice.
- **Respect provider rate limits.** PDL: 10 req/s, Apollo: 100/s per docs (verify).
- **Don't leak raw API responses.** `raw_payload` is audit-only; don't surface in downstream UI.

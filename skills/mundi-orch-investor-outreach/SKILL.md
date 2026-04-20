---
name: mundi-orch-investor-outreach
description: Investor-outreach pipeline — PB investor screener → Apollo/A-Leads contact enrichment → Gemini message personalization → HeyReach campaign push → Supabase CRM log. Use when building an investor outreach campaign from a thesis or list of target firms, refreshing contacts on existing campaigns, or wiring signal-to-outreach handoff.
allowed-tools: Read, Write, Edit, Bash, Task, Grep, Glob, mcp__pitchbook__*, mcp__heyreach__*, mcp__supabase__*, mcp__qmd__*
---

# Mundi Orch — Investor Outreach

## Overview

The end-to-end investor-outreach engine. Turns "I want to reach warm+cold investor candidates on theme X" into scheduled HeyReach campaigns with Supabase CRM writeback and provenance.

Input: thesis or investor-target list (PB investor IDs, fund names, or YAML)
Output: HeyReach list populated + campaigns configured + Supabase log with provenance + digest markdown

## When to use

- Kicking off a new investor outreach sprint for a deal or fund theme
- Refreshing contact data on an existing HeyReach campaign (decision-makers changed)
- Wiring a signal-detection run into outreach without manual CSV handoff
- Follow-up sequence generation (response received → next-step personalization)

Skip if:
- Operator-side outreach (pitching Mundi Princeps itself) — use `apps/investor-outreach-platform/` workflow instead
- Cold-email only (no LinkedIn component) — `saraev-cold-email-campaigns` + `cold-email` are sufficient

## Pipeline (8 steps)

```
[1] Investor screen     → pb_screen_investors with thesis filters (stage, check size, sector, geo)
[2] Entity resolve      → pb_entity_resolve for each hit (dedup, get canonical ID)
[3] People enrich       → pb_person / pb_advisor → decision-makers, partners, associates
[4] Contact enrich      → A-Leads + Apollo MCP (when available) for emails + LinkedIn + phone
[5] Warm-intro map      → pb_warm_intro_path, pb_relationship_graph, pb_investor_overlap
[6] Message personalize → Gemini 3.1 Pro for per-contact opener (thesis fit + warm-intro hook + signal)
[7] HeyReach push       → create list → add leads v2 → add to campaign → schedule
[8] Supabase log        → insert into outreach_campaigns + outreach_contacts with provenance
```

## I/O contract (MWP)

**state_reads:**
- `~/Mundi Princeps/config/api_keys.json` — PB, A-Leads, HeyReach, Supabase
- `~/Mundi Princeps/apps/investor-outreach-platform/` — existing platform pipeline + schema
- `~/Mundi Princeps/apps/investor-outbound-mcp/docs/playbook/INVESTOR_TARGETING_SOP.md` — SOP
- `~/Mundi Princeps/apps/investor-outbound-mcp/docs/playbook/SEGMENTATION_CRITERIA.md` — segmentation
- `~/.claude/projects/.../memory/linkedin-outbound-handoff.md` — Unipile pattern
- `~/.claude/projects/.../memory/reference_heyreach_mcp_keys.md` — HeyReach auth

**state_writes:**
- `apps/investor-outbound-mcp/output/campaigns/<theme>-<date>/` — run artifacts
  - `investors.json` — screener output
  - `contacts.json` — enriched contacts
  - `messages.json` — personalized openers
  - `heyreach-list-id.txt` — list ID for reference
- Supabase tables: `outreach_campaigns`, `outreach_contacts`, `outreach_messages`
- HeyReach list created + campaign configured (idempotent — list name includes date)

## Composition

| step | tool |
|---|---|
| investor screen | `mcp__pitchbook__pb_screen_investors` + thesis YAML |
| entity resolve | `mcp__pitchbook__pb_entity_resolve` |
| person enrich | `mcp__pitchbook__pb_person`, `pb_advisor`, `pb_contact_enrichment` |
| warm intro | `mcp__pitchbook__pb_warm_intro_path`, `pb_relationship_graph`, `pb_investor_overlap` |
| A-Leads / Apollo | `apps/lead-enricher/providers/*` (existing waterfall) |
| message gen | Gemini 3.1 Pro API (pattern from `video-to-action` skill) |
| HeyReach list | `mcp__heyreach__create_empty_list`, `add_leads_to_list_v2`, `add_leads_to_campaign_v2` |
| Supabase log | `mcp__supabase__execute_sql` |

## Safety + rate-limit

- **PB semaphore=2** — do not parallelize beyond 2 concurrent PB calls per account. See `feedback_no_parallel_scraping.md`.
- **HeyReach 100-leads-per-request** batch size. See `reference_heyreach_mcp_keys.md`.
- **Dry-run mode default** — pipeline builds the list + campaigns but does NOT activate them without `--activate` flag.
- Gemini personalization — hold 200 tokens per contact budget; defer long explanations to follow-up messages.
- **Memory: `feedback_linkdrop_faithfulness.md`** — personalization must reference actual PB signals, not invented context. No hallucinated warm-intros.

## Failure modes

| failure | recovery |
|---|---|
| PB 401 mid-screen | checkpoint at step 2 (investors.json) → refresh cookies → resume from step 3 |
| A-Leads rate-limit | continue with PB-only contact data; mark contacts without verified email as `channel: linkedin-only` |
| HeyReach campaign creation fails | list created OK → log list_id to resume; don't re-create on retry |
| Gemini rate-limit | fall back to template-based opener (less personalized but ships) |
| Supabase write fails | keep local JSON + CSV artifacts; surface manual-reconcile warning |

## Invocation

```bash
/mundi:multi-platform-orch investor-outreach --theme=climate-growth-na --dry-run
```

```python
Skill(skill="mundi-orch-investor-outreach", {
  theme_yaml: "apps/deal-origination/themes/climate-growth-na.yaml",
  depth: "full",
  activate: false,
  campaign_name: "climate-growth-na-2026-04-20"
})
```

## Output contract

```json
{
  "run_id": "climate-growth-na-2026-04-20",
  "investors_screened": 127,
  "investors_enriched": 119,
  "contacts_found": 284,
  "contacts_with_email": 231,
  "messages_personalized": 231,
  "heyreach_list_id": "list_...",
  "heyreach_campaign_id": "campaign_...",
  "activated": false,
  "supabase_rows_inserted": {"campaigns": 1, "contacts": 231, "messages": 231},
  "gaps": ["8 investors failed entity_resolve", "53 contacts no verified email"]
}
```

## Cross-references

- **Related:** `apps/investor-outreach-platform/` (production platform), `apps/investor-outbound-mcp/` (MCP layer), `mundi-orch-counterparty-enrich` (per-investor deep dive), `mundi-orch-intent-signal` (upstream signal feeder)
- **Plugin skills:** `saraev-cold-email-campaigns`, `cold-email`, `linkdrop-x-tomdoerr-gnhf-overnight-orchestrator`
- **Memory:** `linkedin-outbound-handoff.md`, `reference_heyreach_mcp_keys.md`, `feedback_no_parallel_scraping.md`
- **KB:** `docs/knowledge-base/wiki/04-lead-generation/INDEX.md`, `wiki/00-workflows/lead-gen-reference.md`
- **Plan source:** `docs/plans/2026-04-19-phase-3-final.md` line 865

## Safety

- **Never activate without dry-run first.** Default behavior is `activate: false` — campaigns are built but not launched.
- **Account safety on PB + HeyReach** — respect semaphores.
- **Personalization must be faithful** — invented context in openers torches reputation.

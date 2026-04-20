---
name: toolkit-scout
description: Concierge index for the Claude Code toolkit on this machine — router-first rule, by-intent map, workflow recipes, and rich family descriptions for the Mundi Princeps workflows. Curated head is hand-maintained; auto-generated inventory lives below the marker and is refreshed by ~/.claude/scripts/build-toolkit-scout.sh.
---

# Toolkit Scout

> ⚠️ **ROUTER-FIRST RULE.** If you are not sure which tool to use for a task, run:
>
> ```bash
> bash ~/.claude/scripts/route.sh "<task description>" --top=5
> ```
>
> **before** scrolling this file or guessing from names. The router scores the full registry against your query and returns ranked matches with invocation syntax. Filter with `--kind=skill|agent|command|mcp|script` as needed.

This file is a concierge, not a phone book. Everything above the marker is hand-maintained: router-first rule → by-intent index → workflow recipes → family descriptions → when-stuck flowchart. The auto-generated inventory (counts, MCP list) is regenerated below the marker on every registry rebuild.

---

## By intent — cross-cutting task → tool map

Map task types to the right tools. Use this when the router's keyword matcher doesn't surface what you need, or to check which families are relevant.

- **Database / Supabase / Postgres** → `supabase` (MCP), `supabase-postgres-best-practices`, `postgres`, `postgres-optimization`, `ai-skills:postgres`, `migration-generator:create-migration`, `mcp__supabase__execute_sql`
- **PitchBook data** → `mcp__pitchbook__*` (103 tools), `/mundi:counterparty-enrich`, `/mundi:origination-run`, `mundi-orch-counterparty-enrich`, `mundi-orch-deal-origination`, `pitchbook-orchestrator` agent
- **CapIQ data** → `apps/capiq-mcp/` (81 tools), `mundi-qmd-auth-refresh-hub` for cookie refresh
- **Deal origination (full pipeline)** → `/mundi:origination-run themes/<theme>.yaml` → `mundi-orch-deal-origination` composes `mundi-orch-counterparty-enrich` + `investment-banking:one-pager` + `private-equity:ic-memo`
- **Intent signals** → `/mundi:intent-signal-run` → `mundi-orch-intent-signal` + `mcp__pitchbook__pb_signal_*` + `mcp__perplexity__perplexity_research`
- **Counterparty enrichment** → `/mundi:counterparty-enrich` → `mundi-orch-counterparty-enrich` + `mcp__pitchbook__pb_entity_resolve` + `pb_signal_enrich`
- **Investor outreach** → `mundi-orch-investor-outreach` + `mcp__heyreach__*` + `mcp__pitchbook__pb_screen_investors` + `apps/lead-enricher/`
- **IC memos / CIMs / pitch decks / LBO / DCF** → `private-equity:ic-memo`, `investment-banking:cim`, `investment-banking:pitch-deck`, `financial-analysis:lbo-model`, `financial-analysis:dcf-model`, `mundi-orch-board-materials`
- **Cold outbound / LinkedIn** → `saraev-outbound-*` family, `saraev-cold-email-campaigns`, `cold-email`, `mcp__heyreach__*`, `linkedin-cli` (Unipile-backed), `link-drop-pipeline`
- **Design / landing pages / sites** → `brand`, `design-system`, `taste-skill`, `saraev-vibe-*` family, `saraev-cinematic-oneshot-site`, `/mundi:clone-site`, `/mundi:kw-subbrand`, `/mundi:investor-portal`, `/mundi:4-sites-one-shot`
- **Testing / Playwright / flaky tests** → `playwright` (skill + `mcp__playwright__*`), `testing:test-fix`, `bug-detective:debug`, `test-engineer` agent, `tdd`, `tdd-mastery`
- **CI / deploy** → `testing:test-fix`, `ci-debugger:analyze-ci-failure`, `devops:ci-pipeline`, `mundi-qmd-ssh-deploy-generalized`, `monorepo-tooling` agent
- **Claude Code config / hooks / agents** → `saraev-claude-code-advanced-hooks`, `git-guardrails-claude-code`, `update-config` skill (for `~/.claude/settings.json`)
- **Video / YouTube** → `video-to-action`, `/mundi:video-to-spec`, `/mundi:youtube-first-check`
- **Multi-LLM debate / consensus / routing** → `/mundi:debate`, `/mundi:consensus`, `mundi-orch-multi-llm-consensus`, `mundi-orch-multi-llm-debate`, `mundi-orch-multi-llm-route`, `linkdrop-x-tom-doerr-multi-llm-council-deliberation`
- **PRD / product** → `prd-generator`, `write-a-prd`, `ariz-product-manager-toolkit`, `pm-execution:create-prd`, `pm-execution:write-prd`, `prd-to-plan`, `prd-to-issues`
- **Security audits** → `/mundi:security-audit`, `security:audit`, `security:hardening`, `mundi-qmd-secret-scan-precommit`, `mundi-qmd-fp-check-install`, `saraev-vibe-app-security-audit`
- **Board materials / investor decks** → `mundi-orch-board-materials`, `investment-banking:pitch-deck`, `financial-analysis:ppt-template-creator`
- **Auth refresh (PB / CapIQ / Supabase)** → `mundi-qmd-auth-refresh-hub`, `apps/pitchbook-mcp/scripts/refresh-pb-cookies.sh`, `apps/capiq-mcp/scripts/refresh-capiq-cookies.sh`
- **Session continuity / past-session lookup** → `mcp__qmd__deep_search`, `mcp__qmd__search`, `mcp__qmd__get`, `mcp__qmd__multi_get`, `~/.claude/projects/-Users-mundiprinceps-Mundi-Princeps/memory/`
- **Document extraction / generation** → `document-skills:pdf`, `document-skills:docx`, `document-skills:pptx`, `document-skills:xlsx`, `document-skills:brand-guidelines`, `document-skills:doc-coauthoring`
- **Google Workspace** → `gws` MCP (`mcp__gws__*` — Docs, Drive, Sheets, Calendar), `ai-skills:google-drive`, `ai-skills:google-sheets`, `ai-skills:google-docs`
- **Microsoft 365** → `ms365` MCP (`mcp__ms365__*` — Mail, Calendar, Teams, SharePoint)

---

## Recipes — explicit workflow → tool-chain entries

Canonical workflows for Mundi's day-to-day. Each recipe names the primary tool, the orchestrator (if any), supporting tools, and safety constraints.

### Recipe: Counterparty enrichment
- **Primary:** `/mundi:counterparty-enrich "Bessemer Venture Partners" --kind=investor`
- **Orchestrator:** `mundi-orch-counterparty-enrich`
- **Supporting:** `mcp__pitchbook__pb_entity_resolve`, `pb_company` / `pb_investor` / `pb_lp` / `pb_advisor`, `pb_signal_enrich`, `mcp__perplexity__perplexity_research`
- **Safety:** semaphore=2 on PitchBook. Never run parallel scrapers on same cookies (account ban risk — see memory `feedback_no_parallel_scraping.md`).

### Recipe: Deal-origination pipeline from a theme
- **Primary:** `/mundi:origination-run themes/<theme>.yaml`
- **Orchestrator:** `mundi-orch-deal-origination`
- **Composes:** `mundi-orch-counterparty-enrich`, `investment-banking:one-pager`, `private-equity:ic-memo`
- **Data:** `apps/deal-origination/themes/`, `mcp__pitchbook__pb_screen_companies`

### Recipe: Write an IC memo for a new deal
- **Primary:** `private-equity:ic-memo`
- **Supporting models:** `financial-analysis:dcf-model`, `financial-analysis:lbo-model`, `financial-analysis:comps-analysis`
- **Data gathering:** `mcp__pitchbook__pb_ic_memo_data`, `pb_company_deep_dive`, `pb_management_assessment`
- **Format:** `document-skills:docx` for final output

### Recipe: Generate board materials from a data room
- **Primary:** `mundi-orch-board-materials`
- **Data sources:** Google Drive (`mcp__gws__*`), SharePoint (`mcp__ms365__*`)
- **Deck construction:** `investment-banking:pitch-deck`, `financial-analysis:ppt-template-creator`
- **Extract:** `document-skills:pdf` / `docx` / `pptx`

### Recipe: Refresh PB / CapIQ cookies after 401
- **Runbook:** `mundi-qmd-auth-refresh-hub`
- **Scripts:** `apps/pitchbook-mcp/scripts/refresh-pb-cookies.sh`, `apps/capiq-mcp/scripts/refresh-capiq-cookies.sh`
- **Critical:** do NOT retry in a loop. See `memory/feedback_pb_account_safety_protocol.md`.

### Recipe: Deploy an MCP to Achilles
- **Runbook:** `mundi-qmd-ssh-deploy-generalized`
- **Template:** `apps/pitchbook-mcp/scripts/deploy-pb-counterparty-achilles.sh` (canonical)
- **Per-app ports:** pitchbook=8766, capiq=8768, investor-outbound=8770

### Recipe: Investor outreach campaign from thesis
- **Primary:** `mundi-orch-investor-outreach`
- **Screener:** `mcp__pitchbook__pb_screen_investors`
- **Contacts:** A-Leads + Apollo via `apps/lead-enricher/` + `mcp__heyreach__*`
- **Message gen:** Gemini 3.1 Pro via `mundi-orch-multi-llm-route`
- **Schedule:** HeyReach campaign + Supabase CRM log
- **Default:** dry-run. `--activate` to go live.

### Recipe: Intent-signal run on a theme
- **Primary:** `/mundi:intent-signal-run signals/<theme>.yaml`
- **Orchestrator:** `mundi-orch-intent-signal`
- **Signals:** `mcp__pitchbook__pb_signal_advisor_hired`, `pb_signal_debt_maturing`, `pb_signal_fund_exits_due`, `pb_signal_management_changes`, `pb_signal_no_deal_in_years`
- **Grounding:** `mcp__perplexity__perplexity_research`

### Recipe: Multi-LLM decision deliberation
- **Agreement-oriented:** `mundi-orch-multi-llm-consensus`
- **Adversarial:** `mundi-orch-multi-llm-debate`
- **Task→provider routing:** `mundi-orch-multi-llm-route`
- **External council:** `linkdrop-x-tom-doerr-multi-llm-council-deliberation`
- **Claude-only alternatives:** `/mundi:debate`, `/mundi:consensus`

### Recipe: LinkedIn profile / outreach automation
- **Tools:** `linkedin-cli` (Unipile-backed), `mcp__heyreach__*`, `saraev-lead-scraper`, `saraev-outbound-*` family
- **Memory reference:** `linkedin-outbound-handoff.md` (Unipile handoff pattern)
- **Pipeline:** Campaign YAML → Unipile SN search → filter open profiles → HeyReach list → campaign

### Recipe: Postgres query against Kadenwood Supabase
- **Primary:** `mcp__supabase__execute_sql`
- **Best practices:** `supabase-postgres-best-practices`, `postgres-optimization`
- **Migrations:** `migration-generator:create-migration`, `mcp__supabase__apply_migration`

### Recipe: Fix a flaky Playwright test
- **Primary:** `playwright` skill + `mcp__playwright__*`
- **Debug:** `testing:test-fix`, `bug-detective:debug`
- **Agent:** `test-engineer`

### Recipe: Ship a code change to production
- **Command:** `/ship` (see `~/.claude/skills/ship-software/`)
- **CI gates:** `testing:test-coverage`, `review:code`, `review:security`
- **Deploy:** `mundi-qmd-ssh-deploy-generalized`

### Recipe: Audit CLAUDE.md / memory for staleness
- **Command:** `/mundi:claude-md-audit`
- **Framework:** Lehmann's 5 filters (relevance, freshness, model-version, redundancy, over-constraining)

### Recipe: Write a PRD
- **Primary:** `write-a-prd` OR `prd-generator`
- **Alternative:** `pm-execution:create-prd`, `pm-execution:write-prd`
- **Research first:** `ariz-product-manager-toolkit`, `ariz-product-discovery`
- **Convert to issues:** `prd-to-issues`, `prd-to-plan`

### Recipe: Generate a new landing page / site
- **Primary:** `/mundi:clone-site`, `/mundi:kw-subbrand`, `/mundi:4-sites-one-shot`
- **Design:** `saraev-cinematic-oneshot-site`, `brand`, `taste-skill`
- **Design variants:** `design-system`, `saraev-3d-scroll-hero`

### Recipe: Secret scan / prevent commit leaks
- **Install:** `mundi-qmd-secret-scan-precommit`
- **Manual:** `~/.claude/scripts/phase3/check-secrets.sh`
- **Pre-rsync:** `~/.claude/scripts/phase3/pre-rsync-achilles-grep.sh`

### Recipe: Lead enrichment pipeline
- **Primary:** `apps/lead-enricher/`
- **Runbook:** `mundi-qmd-lead-enricher-supabase-writer` (wires SupabaseWriter into waterfall)
- **Providers:** A-Leads → Apollo → PDL (waterfall cascade)

### Recipe: Onboard a new MCP
- **Audit:** `mundi-qmd-intent-tool-coverage`
- **Pattern:** `apps/pitchbook-mcp/` + `apps/capiq-mcp/` as templates
- **Deploy:** `mundi-qmd-ssh-deploy-generalized`

### Recipe: Past-session lookup / session continuity
- **Primary:** `mcp__qmd__deep_search`, `mcp__qmd__search`, `mcp__qmd__get`, `mcp__qmd__multi_get`
- **Cross-session memory:** `~/.claude/projects/-Users-mundiprinceps-Mundi-Princeps/memory/`

### Recipe: Ingest a URL into skills / KB / registry
- **Agent:** `link-drop` (invocable via `Task(subagent_type="link-drop", prompt="<URL>")`)
- **Slash:** `/mundi:link-drop <URL>`
- **Skill:** `link-drop-pipeline`

### Recipe: Evolve an existing skill with new material
- **Skill:** `autoresearch-evolve`
- **Note:** additive only — never destructive rewrites

---

## Skill families — what each one covers

Replaces raw slug-prefix counts with descriptions. Counts below are approximate and refresh automatically in the inventory table below the marker.

| Family | Approx count | What's in it |
|---|---|---|
| `saraev-cc-*` | ~182 | Claude Code workflow tips from Saraev — hooks, n8n, terminal, voice, keyboard shortcuts, plan mode, worktrees |
| `saraev-vibe-*` | ~83 | "Vibe coding" patterns — SaaS scaffolds, one-shot sites, UI iteration, design feedback loops |
| `saraev-biz-*` | ~74 | Business patterns — agent design, outreach psychology, offer framing, retainer strategies |
| `saraev-infra-*` | ~69 | Infrastructure — Modal, Supabase, deployment, database schemas, security audits |
| `saraev-outbound-*` | ~49 | Cold outbound tactics — email, LinkedIn, forum autoresponder, casualize templates, AI tooling cost models |
| `mundi-qmd-*` | ~33 | Operational runbooks — auth refresh, secret scan, SSH deploy, env mgmt, async polling |
| `mundi-orch-*` | 8 | End-to-end orchestrators — counterparty, origination, intent signal, board materials, multi-LLM |
| `linkdrop-x-*` | ~12 | External community pointers (awesome-claude-code, council-of-high-intelligence, micrograd) |
| `ariz-*` (all subs) | ~130 | Consulting advisor personas — CPO, CTO, CMO, CFO, CISO, founder coach, market scan |
| `geo-*` | ~11 | GEO (Generative Engine Optimization) — citability, schemas, crawlers, llmstxt |
| `gstack-*` | ~13 | Product team orchestration — planning, shipping, freeze/unfreeze, worktrees |
| `tob-*` | ~9 | Trail of Bits security patterns — fuzzing, SARIF, semgrep, vulnerability scanners |
| `hugging-*` | ~8 | HuggingFace ecosystem — datasets, evaluation, model training, Gradio, paper publishing |
| `hassid-claude-*` | ~6 | Hassid's Claude 101 onboarding series |
| `cloudflare-*` | ~5 | Cloudflare agents, Workers, Durable Objects, Wrangler |
| `better-auth-*` | ~5 | better-auth library patterns (email/password, 2FA, organization) |
| `expo-*` | ~7 | Expo / React Native patterns |
| `terraform-*` | ~6 | Terraform modules, stacks, test, style guide |
| `investment-banking:*` | 11 | IB materials — CIM, teaser, pitch deck, merger model, buyer list, one-pager, process letter, datapack, strip-profile |
| `financial-analysis:*` | 13 | Financial models — 3-statement, DCF, LBO, comps, PPT templates, deck review, skill-creator |
| `private-equity:*` | 9 | PE workflow — DD checklist, IC memo, screen deal, value creation, portfolio, returns, add-on targets |
| `document-skills:*` | ~17 | Doc generation / manipulation — PDF, DOCX, PPTX, XLSX, brand guidelines, skill creator |
| `apollo-pack:*` | 24 | Apollo.io sales enablement — workflows, CI, observability, migration, rate limits, debug bundles |
| `pm-*:*` (8 packs) | ~85 | Product management — discovery, strategy, execution, market research, analytics, GTM, growth, toolkit |
| `superpowers:*` | 14 | Superpowers CLI — git worktrees, parallel agents, subagent-driven dev, TDD, code review |
| `ai-skills:*` | 20 | AI-first integrations — Gmail, Google Drive/Sheets/Calendar/Slides, Atlassian, Postgres, MSSQL, Imagen |
| `mundi-*` root | N/A | `/mundi:*` slash commands (21 workflows) — see `docs/knowledge-base/wiki/00-workflows/INDEX.md` |

---

## When stuck — flowchart

Can't find the right tool?

1. Run `bash ~/.claude/scripts/route.sh "<task>" --top=5` — keyword + tie-break matcher
2. Miss? Check the "By intent" index above
3. Miss? Grep: `grep -ri "<keyword>" ~/.claude/skills/*/SKILL.md | head`
4. Miss? Check agents: `ls ~/.claude/agents/ | grep -i <keyword>`
5. Miss? Check slash commands: `ls ~/.claude/commands/ | grep <keyword>`
6. Still miss? `mcp__qmd__deep_search` for past sessions
7. Still miss? It probably doesn't exist yet — decide: write it, or use the closest approximation

---

## Maintenance

- **Add a new recipe:** edit this file above the marker. `build-toolkit-scout.sh` preserves the curated head byte-for-byte on regen.
- **Refresh counts:** `bash ~/.claude/scripts/build-toolkit-scout.sh` (runs automatically after `build-registry.sh`).
- **Marker invariant:** exactly one `<!-- AUTO-GENERATED BELOW -->` marker must exist in this file. 0 or 2+ markers cause the regen to abort or fall back to the default template.

<!-- AUTO-GENERATED BELOW — DO NOT EDIT MANUALLY — run ~/.claude/scripts/build-toolkit-scout.sh to regenerate -->
# Auto-generated inventory

**Registry built:** `2026-04-20T12:04:43Z`  
**Total items:** 2015  
**Source:** `~/.claude/registry.json`  
**Regenerate:** `bash ~/.claude/scripts/build-toolkit-scout.sh`

## Counts by kind

| Kind | Count |
|------|-------|
| agent | 171 |
| command | 344 |
| mcp | 16 |
| script | 204 |
| skill | 1280 |

## Skill families (by slug prefix)

_See curated head above for rich family descriptions. This table is raw counts only._

| Family | Count |
|--------|-------|
| `saraev-cc-*` | 182 |
| `saraev-vibe-*` | 83 |
| `saraev-biz-*` | 74 |
| `saraev-infra-*` | 69 |
| `saraev-outbound-*` | 49 |
| `mundi-qmd-*` | 33 |
| `apollo-pack:` | 24 |
| `ai-skills:` | 20 |
| `document-skills:` | 17 |
| `pm-execution:` | 15 |
| `superpowers:` | 14 |
| `pm-product-discovery:` | 13 |
| `linkdrop-x-*` | 12 |
| `pm-product-strategy:` | 12 |
| `geo-*` | 11 |
| `gstack-*` | 10 |
| `financial-analysis:` | 9 |
| `investment-banking:` | 9 |
| `private-equity:` | 9 |
| `tob-*` | 9 |
| `hugging-*` | 8 |
| `mundi-orch-*` | 8 |
| `ariz-marketing-*` | 7 |
| `context-mode:` | 7 |
| `expo-*` | 7 |
| `pm-market-research:` | 7 |
| `hassid-claude-*` | 6 |
| `hassid-skills-*` | 6 |
| `pm-go-to-market:` | 6 |
| `terraform-*` | 6 |
| `ariz-product-*` | 5 |
| `better-*` | 5 |
| `cloudflare-*` | 5 |
| `content-*` | 5 |
| `pm-marketing-growth:` | 5 |
| `saraev-claude-*` | 5 |
| `ariz-content-*` | 4 |
| `claude-mem:` | 4 |
| `hassid-cc-*` | 4 |
| `pm-toolkit:` | 4 |
| (other standalone) | 410 |

## Agent families

| Family | Count |
|--------|-------|
| `gsd-*` | 12 |
| `geo-*` | 5 |
| `data-*` | 4 |
| `api-*` | 3 |
| `database-*` | 3 |
| `frontend-*` | 3 |
| `security-*` | 3 |
| `backend-*` | 2 |
| `code-*` | 2 |
| `compliance-*` | 2 |
| `documentation-*` | 2 |
| `error-*` | 2 |
| `fullstack-*` | 2 |
| `monorepo-*` | 2 |
| `performance-*` | 2 |
| `test-*` | 2 |
| (other standalone) | 120 |

## Command namespaces

| Namespace | Count |
|-----------|-------|
| `/gsd:*` | 32 |
| `/mundi:*` | 30 |
| `/(root):*` (root slash-commands) | 13 |
| `/git:*` | 7 |
| `/review:*` | 7 |
| `/architecture:*` | 6 |
| `/testing:*` | 6 |
| `/devops:*` | 5 |
| `/documentation:*` | 5 |
| `/refactoring:*` | 5 |
| `/security:*` | 5 |
| `/deploy-pilot:*` | 3 |
| `/doc-forge:*` | 3 |
| `/workflow:*` | 3 |
| `/a11y-audit:*` | 2 |
| `/accessibility-checker:*` | 2 |
| `/adr-writer:*` | 2 |
| `/ai-prompt-lab:*` | 2 |
| `/analytics-reporter:*` | 2 |
| `/android-developer:*` | 2 |
| `/api-architect:*` | 2 |
| `/api-benchmarker:*` | 2 |
| `/api-tester:*` | 2 |
| `/aws-helper:*` | 2 |
| `/azure-helper:*` | 2 |
| `/backend-architect:*` | 2 |
| `/bug-detective:*` | 2 |
| `/bundle-analyzer:*` | 2 |
| `/ci-debugger:*` | 2 |
| `/code-architect:*` | 2 |
| `/code-explainer:*` | 2 |
| `/code-guardian:*` | 2 |
| `/color-contrast:*` | 2 |
| `/commit-commands:*` | 2 |
| `/complexity-reducer:*` | 2 |
| `/compliance-checker:*` | 2 |
| `/content-creator:*` | 2 |
| `/contract-tester:*` | 2 |
| `/create-worktrees:*` | 2 |
| `/cron-scheduler:*` | 2 |

## MCP servers

- `clickup`
- `code-review-graph`
- `context7`
- `github`
- `gws`
- `heyreach`
- `ms365`
- `n8n`
- `pencil`
- `perplexity`
- `pitchbook`
- `playwright`
- `qmd`
- `supabase`
- `token-optimizer`
- `token-savior`

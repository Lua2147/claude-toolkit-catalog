# Workflow Guide — What to Use When

Quick reference mapping your actual workflows to the best installed tools. Consult this before starting any task.

---

## 1. Deal Origination & Signal Pipeline

| Task | Best Tool | Type |
|------|-----------|------|
| Screen inbound deal (CIM/teaser) | `private-equity:screen-deal` | Plugin skill |
| Build comp analysis | `financial-analysis:comps` | Plugin skill |
| DCF valuation | `financial-analysis:dcf` | Plugin skill |
| LBO model | `financial-analysis:lbo` | Plugin skill |
| 3-statement model | `financial-analysis:3-statements` | Plugin skill |
| SEC filing data (10-K, 13F, Form 4) | `edgartools` | Skill |
| Stock/forex/crypto data | `alpha-vantage` | Skill |
| Macro economic indicators | `fred-economic-data` | Skill |
| Hedge fund position tracking | `hedgefundmonitor` | Skill |
| US fiscal/treasury data | `usfiscaldata` | Skill |
| Market research report (50+ pages) | `market-research-reports` | Skill |
| Competitive landscape analysis | `competitive-landscape` | Skill |
| Deep multi-source research | `mcp__perplexity__perplexity_research` | MCP tool |
| Quick fact lookup | `mcp__perplexity__perplexity_ask` | MCP tool |
| Evidence verification | `deep-research` | Skill (Gemini) |
| Signal scoring optimization | `autoresearch-optimizer` | Skill |

## 2. LinkedIn Outbound (Unipile + HeyReach)

| Task | Best Tool | Type |
|------|-----------|------|
| Get all campaigns | `mcp__heyreach__get_all_campaigns` | MCP tool |
| Add leads to campaign | `mcp__heyreach__add_leads_to_campaign_v2` | MCP tool |
| Add leads to list | `mcp__heyreach__add_leads_to_list_v2` | MCP tool |
| Pause/resume campaign | `mcp__heyreach__pause_campaign` / `resume_campaign` | MCP tool |
| Get campaign stats | `mcp__heyreach__get_overall_stats` | MCP tool |
| Get conversations | `mcp__heyreach__get_conversations_v2` | MCP tool |
| Send message | `mcp__heyreach__send_message` | MCP tool |
| Create webhook for replies | `mcp__heyreach__create_webhook` | MCP tool |
| Write cold outreach copy | `cold-email` | Skill |
| Design email sequence | `email-sequence` | Skill |
| Deploy campaign monitor workflow | `mcp__n8n__n8n_create_workflow` | MCP tool |

## 3. Email Campaigns (Graph API / 294 Inboxes)

| Task | Best Tool | Type |
|------|-----------|------|
| Send single email (Kadenwood) | `/kw-send-josh` or `/kw-send-ruben` | Slash command |
| Send bulk email | `scripts/kw-bulk-send.py` | Script |
| Read inbox / check replies | `mcp__ms365__list-mail-messages` | MCP tool |
| Search for specific email | `mcp__ms365__search-query` | MCP tool |
| Create draft | `mcp__ms365__create-draft-email` | MCP tool |
| Send via MS365 MCP | `mcp__ms365__send-mail` | MCP tool |
| Monitor shared mailbox | `mcp__ms365__list-shared-mailbox-messages` | MCP tool |
| Schedule follow-up | `mcp__claude_ai_Google_Calendar__gcal_create_event` | MCP tool |
| Read Gmail | `ai-skills:gmail` | Plugin skill |
| Write cold email copy | `cold-email` | Skill |
| Brand-consistent copy | `brand-voice` | Skill |

## 4. Client Work (DI, WWC, Fantuan)

| Task | Best Tool | Type |
|------|-----------|------|
| Draft CIM | `investment-banking:cim` | Plugin skill |
| Draft teaser | `investment-banking:teaser` | Plugin skill |
| Build buyer list | `investment-banking:buyer-list` | Plugin skill |
| One-page strip profile | `investment-banking:one-pager` | Plugin skill |
| IC memo | `private-equity:ic-memo` | Plugin skill |
| DD checklist | `private-equity:dd-checklist` | Plugin skill |
| DD meeting prep | `private-equity:dd-prep` | Plugin skill |
| Value creation plan | `private-equity:value-creation` | Plugin skill |
| Build pitch deck | `investment-banking:pitch-deck` + `document-skills:pptx` | Plugin skills |
| QC presentation deck | `financial-analysis:check-deck` | Plugin skill |
| Research for board materials | `mcp__perplexity__perplexity_research` | MCP tool |
| Investor materials consistency | `investor-materials` | Skill |
| Stress-test deliverable | `grill-me` | Skill |
| Read Google Doc | `mcp__gws__readGoogleDoc` | MCP tool |
| Write to Google Doc | `mcp__gws__appendToGoogleDoc` | MCP tool |
| Search Google Drive | `mcp__gws__listFolderContents` | MCP tool |
| Read/write Google Sheets | `mcp__google-sheets__get_sheet_data` / `update_cells` | MCP tool |

## 5. CRM Dashboard (Next.js + Supabase)

| Task | Best Tool | Type |
|------|-----------|------|
| Query Supabase directly | `mcp__supabase__execute_sql` | MCP tool (needs re-auth) |
| Run migration | `mcp__supabase__apply_migration` | MCP tool |
| List tables | `mcp__supabase__list_tables` | MCP tool |
| Generate TypeScript types | `mcp__supabase__generate_typescript_types` | MCP tool |
| Database optimization | `database-optimization` + `postgres-optimization` | Skills |
| Revenue metrics framework | `revenue-metrics` | Skill |
| Frontend component | `frontend-design` + `taste-skill` | Skills |
| React patterns | `react-patterns` + `composition-patterns` | Skills |
| Next.js patterns | `next-best-practices` + `nextjs-mastery` | Skills |

## 6. Deck Generation (Mainframe)

| Task | Best Tool | Type |
|------|-----------|------|
| Generate PPTX | `document-skills:pptx` | Plugin skill |
| Generate PDF | `document-skills:pdf` | Plugin skill |
| Visual QA of deck | `gstack-qa` or `mcp__pencil__get_screenshot` | Skill / MCP |
| High-end design style | `taste-skill` + `soft-skill` | Skills |
| Brutalist/minimal style | `brutalist-skill` + `minimalist-skill` | Skills |
| Anti-slop enforcement | `output-skill` | Skill |
| Brand consistency | `brand-voice` | Skill |

## 7. Web Scraping & Data Collection

| Task | Best Tool | Type |
|------|-----------|------|
| Cloudflare-protected sites | `scrapling` (StealthyFetcher) | Skill |
| Authenticated scraping (CapIQ, PitchBook) | `scrapling` (session_login template) + `browser-use` | Skills |
| Browser automation | `mcp__playwright__browser_*` | MCP tools |
| AI-driven browser control | `browser-use` + `remote-browser` | Skills |
| macOS desktop automation | `automation-mcp` | Skill |
| API documentation lookup | `get-api-docs` (Context Hub, 400+ libraries) | Skill |
| Up-to-date library docs | `context7-docs:fetch-docs` | Plugin skill |

## 8. Session & Project Management

| Task | Best Tool | Type |
|------|-----------|------|
| Start session | `/start` | Slash command |
| End session | `/wrap-up` | Slash command |
| Commit + push | `/commit-push` | Slash command |
| Quick commit (no push) | `/quick-commit` | Slash command |
| Code review | `/grill` | Slash command |
| Tech debt sweep | `/techdebt` | Slash command |
| Search past sessions | `mcp__qmd__deep_search` | MCP tool |
| Retrieve specific session | `mcp__qmd__get` | MCP tool |
| Sessions by date | `mcp__qmd__multi_get` with date glob | MCP tool |
| Memory consolidation | `/rem-sleep` | Slash command |
| Plan implementation | `superpowers:writing-plans` | Plugin skill |
| Execute plan | `superpowers:executing-plans` | Plugin skill |
| Brainstorm design | `superpowers:brainstorming` | Plugin skill |
| Debug systematically | `superpowers:systematic-debugging` | Plugin skill |
| Parallel agent work | `superpowers:dispatching-parallel-agents` | Plugin skill |
| Git worktrees | `superpowers:using-git-worktrees` | Plugin skill |
| Recurring task | `/loop` | Slash command |

## 9. Research & Analysis

| Task | Best Tool | Type |
|------|-----------|------|
| Deep web research (30s+, cited) | `mcp__perplexity__perplexity_research` | MCP tool |
| Quick web search | `mcp__perplexity__perplexity_search` | MCP tool |
| Reasoning/analysis | `mcp__perplexity__perplexity_reason` | MCP tool |
| Multi-source research | `research` | Skill |
| Read arXiv paper | `read-arxiv-paper` | Skill |
| Statistical analysis | `statistical-analysis` | Skill |
| EDA workflow | `exploratory-data-analysis` | Skill |
| Time series forecasting | `timesfm-forecasting` | Skill |
| Data processing (large) | `polars` (in-RAM) or `dask` (larger-than-RAM) | Skills |

---

## Broken / Needs Attention

| Server | Issue | Fix |
|--------|-------|-----|
| **Supabase** | Dual config conflict, auth expired | Pick one config, re-auth |
| **ClickUp** | OAuth expired | Re-auth at mcp.clickup.com |
| **GWS duplicate** | gws + google-workspace = same server twice | Remove one from config |

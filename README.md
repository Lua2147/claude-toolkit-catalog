# Claude Code Toolkit Catalog

Full Claude Code toolkit — skills, agents, commands, GSD pipeline system, and configuration. Clone and install to get everything working in minutes.

## Quick Stats

| Category | Count | Location |
|----------|-------|----------|
| Custom Skills | 252 | `skills/` |
| Custom Agents | 168 | `agents/` |
| Slash Commands | 303 | `commands/` |
| Plugins (as commands) | 120 | `commands/` + `plugins/` |
| Rules | 15 | `rules/` |
| Contexts | 5 | `contexts/` |
| CLAUDE.md Templates | 7 | `templates/claude-md/` |
| GSD Pipeline System | 96 files | `gsd/` |
| Plugin Packs | 10 (300+ skills) | Install separately |
| MCP Servers | 10 | Configure in `~/.claude.json` |
| CLI Tools | 6 | Install separately |

## Claude Certified Architect Gap Skills

| Skill | Exam Domain | Weight | Gaps Covered |
|---|---|---|---|
| `agentic-orchestration-patterns` | D1: Agentic Architecture | 27% | Fork sessions, escalation protocols, state persistence, hook lifecycle |
| `tool-design-patterns` | D2: Tool Design & MCP | 18% | Tool descriptions, error responses, tool_choice, built-in tools |
| `claude-code-ci` | D3: Config & Workflows | 20% | CI/CD integration, non-interactive mode, PR automation |
| `claude-code-config-advanced` | D3: Config & Workflows | 20% | Glob rules, plan mode decisions, iterative refinement |
| `structured-extraction` | D4: Prompt & Output | 20% | Few-shot extraction, validation-retry loops |
| `message-batches-api` | D4: Prompt & Output | 20% | Batch processing at 50% cost, 10K+ items |
| `ensemble-review` | D4: Prompt & Output | 20% | Multi-instance review, majority vote aggregation |
| `confidence-calibration` | D4/D5 | 20%/15% | Confidence scoring, routing, calibration |
| `context-reliability` | D5: Context & Reliability | 15% | Summarization traps, lost-in-middle, persistent facts |
| `information-provenance` | D5: Context & Reliability | 15% | Claim-source mappings, escalation triggers, exploration protocol |

## Installation

```bash
git clone https://github.com/Lua2147/claude-toolkit-catalog.git
cd claude-toolkit-catalog
./install.sh
```

Or install manually:

```bash
# Skills
cp -R skills/* ~/.claude/skills/

# Agents
cp agents/*.md ~/.claude/agents/

# Commands (includes subdirectories)
cp commands/*.md ~/.claude/commands/
for dir in commands/*/; do cp -R "$dir" ~/.claude/commands/; done

# Rules, Contexts, Templates
cp -R rules ~/.claude/rules
cp -R contexts ~/.claude/contexts
mkdir -p ~/.claude/templates && cp -R templates/claude-md ~/.claude/templates/

# GSD Pipeline System
cp -R gsd ~/.claude/get-shit-done
```

---

## Table of Contents

- [Plugin Packs](#plugin-packs)
- [Custom Skills](#custom-skills)
- [MCP Servers](#mcp-servers)
- [Custom Agents](#custom-agents)
- [Slash Commands](#slash-commands)
- [CLI Tools](#cli-tools)
- [Hooks & Automation](#hooks--automation)
- [Setup Guide](#setup-guide)

---

## Plugin Packs

### Core Document & AI Plugins

| Plugin | Provider | What It Does |
|--------|----------|-------------|
| **claude-mem** | thedotmack | Session memory persistence, context consolidation, semantic search across conversations |
| **document-skills** | anthropic-agent-skills | PDF, PPTX, DOCX, XLSX, frontend design, web artifacts, MCP builder, internal comms |
| **pair-programmer** | claude-code | Screen recording, audio capture, visual AI feedback, real-time pair programming |

### Domain Plugins

| Plugin | Provider | What It Does |
|--------|----------|-------------|
| **superpowers** | superpowers-dev | TDD, debugging, brainstorming, code review, plan execution, git worktrees, parallel agents |
| **financial-analysis** | financial-services-plugins | 3-statement models, DCF, LBO, comps, competitive analysis, deck QC |
| **investment-banking** | financial-services-plugins | CIM, teasers, one-pagers, buyer lists, merger models, process letters, pitch decks |
| **private-equity** | financial-services-plugins | DD checklists, IC memos, deal screening, portfolio ops, returns, value creation |
| **apollo-pack** | claude-code-plugins-plus | 25+ skills for Apollo.io API, sequences, rate limits, webhooks |
| **ai-skills** | ai-skills | Google Workspace, Imagen, Jules, deep-research, ElevenLabs, Manus, databases |

### Product Management Plugins

| Plugin | Provider | What It Does |
|--------|----------|-------------|
| **pm-product-discovery** | pm-skills | User research, brainstorming, assumption mapping, interview scripts |
| **pm-product-strategy** | pm-skills | Business models, PESTLE, Porter's Five Forces, lean canvas, pricing |
| **pm-execution** | pm-skills | PRDs, sprint planning, OKRs, release notes, stakeholder maps |
| **pm-market-research** | pm-skills | Market sizing, segments, personas, sentiment, competitor analysis |
| **pm-data-analytics** | pm-skills | Cohort analysis, A/B testing, SQL queries |
| **pm-go-to-market** | pm-skills | GTM strategy, growth loops, ICPs, battlecards |
| **pm-marketing-growth** | pm-skills | North star metrics, positioning, product naming |
| **pm-toolkit** | pm-skills | NDAs, privacy policies, resume review, grammar check |

---

## Custom Skills

### Workflow & Meta

| Skill | What It Does |
|-------|-------------|
| **toolkit-scout** | **Mandatory before any non-trivial task.** Scans 212 skills, 40 agents, 10 plugin packs, 10 MCP servers, 70+ scripts, CLI tools, and reference repos. |
| **rem-sleep** | Consolidates and defrags memory files across sessions |
| **wrap-up** | End-of-session summary, context handoff, memory write |
| **insights** | Analyzes correction patterns and workflow efficiency |
| **scout** | Surfaces relevant context from claude-mem history |
| **boris** | 43 Claude Code workflow tips (parallel work, plan mode, hooks, worktrees) |
| **refine** | Self-scoring convergence loops — iterates until output quality plateaus |
| **coding-agent-loops** | Persistent tmux coding sessions with Claude Code retry loops |
| **cron-guide** | Reference for scheduling recurring tasks and heartbeats |

### Frontend & UI (SummonAI Kit + Vendor)

| Skill | Source | What It Does |
|-------|--------|-------------|
| **nextjs** | SummonAI Kit | Next.js App Router, SSR, routing, middleware |
| **next-best-practices** | Vercel | Official Next.js patterns and conventions |
| **next-cache-components** | Vercel | Caching strategies and cache-aware components |
| **next-upgrade** | Vercel | Next.js version upgrade workflows |
| **react** | SummonAI Kit | React components, hooks, state management |
| **react-best-practices** | Vercel | Official React patterns and optimization |
| **composition-patterns** | Vercel | React component composition and reuse |
| **typescript** | SummonAI Kit | TypeScript types, generics, strict config |
| **frontend-design** | Anthropic | Bold UI design, typography, color systems |
| **web-design-guidelines** | Vercel | Web design standards compliance |
| **remotion** | Remotion | Programmatic video creation with React |

### Backend & API

| Skill | Source | What It Does |
|-------|--------|-------------|
| **python** | SummonAI Kit | Python development, async, testing |
| **fastapi** | SummonAI Kit | FastAPI routes, services, database integration |
| **stripe-best-practices** | Stripe | Payment integration patterns |
| **upgrade-stripe** | Stripe | Stripe SDK/API version upgrades |
| **better-auth-*** | Better Auth | Authentication (5 skills: best-practices, create-auth, email/password, org, 2FA) |

### Database

| Skill | Source | What It Does |
|-------|--------|-------------|
| **supabase** | SummonAI Kit | Client setup, RLS, migrations, Edge Functions |
| **supabase-postgres-best-practices** | Supabase (official) | PostgreSQL performance optimization |
| **postgres** | Community | PostgreSQL patterns |

### Browser Automation

| Skill | Source | What It Does |
|-------|--------|-------------|
| **playwright** | SummonAI Kit | Playwright testing, selectors, CI config |
| **stagehand** | SummonAI Kit | AI-driven browser automation |

### Cloud & Infrastructure

| Skill | Source | What It Does |
|-------|--------|-------------|
| **cloudflare-agents-sdk** | Cloudflare | Stateful AI agents with scheduling, RPC, MCP |
| **cloudflare-building-ai-agent** | Cloudflare | AI agents with state and WebSockets |
| **cloudflare-durable-objects** | Cloudflare | Stateful coordination with SQLite |
| **cloudflare-web-perf** | Cloudflare | Core Web Vitals auditing |
| **cloudflare-wrangler** | Cloudflare | Workers, KV, R2, D1, Queues deployment |
| **terraform-*** | HashiCorp | 6 skills: code gen, modules, style, stacks, imports, Azure |
| **composio** | Composio | Connect to 1000+ SaaS apps with managed auth |
| **expo-*** | Expo | 9 skills: deployment, CI/CD, API routes, SwiftUI, Jetpack, Tailwind |

### Financial & Data (K-Dense-AI)

| Skill | What It Does |
|-------|-------------|
| **edgartools** | SEC EDGAR financial data and regulatory filings |
| **alpha-vantage** | Market data and financial time series |
| **fred-economic-data** | Federal Reserve economic indicators |
| **usfiscaldata** | US fiscal and treasury data |
| **denario** | Financial calculations and modeling |
| **hedgefundmonitor** | Hedge fund tracking and analysis |
| **timesfm-forecasting** | Time series forecasting |
| **statistical-analysis** | Statistical modeling and hypothesis testing |
| **exploratory-data-analysis** | EDA workflows and visualization |
| **polars** | High-performance dataframes |
| **dask** | Parallel computing for large datasets |
| **market-research-reports** | Market research generation |

### AI & ML

| Skill | Source | What It Does |
|-------|--------|-------------|
| **claude-agent-sdk** | SummonAI Kit | Claude Agent SDK, multi-agent orchestration |
| **gemini-api-dev** | Google | Gemini API development |
| **gemini-interactions-api** | Google | Gemini interactions and conversations |
| **gemini-live-api-dev** | Google | Gemini Live API real-time interactions |
| **vertex-ai-api-dev** | Google | Vertex AI platform development |
| **hf-cli** | HuggingFace | HF Hub CLI for models, datasets, repos |
| **hugging-face-*** | HuggingFace | 11 skills: datasets, model training (TRL), evaluation, jobs, trackio, Gradio, MCP, dataset-viewer, paper-publisher, tool-builder |
| **replicate** | Replicate | Run AI models via Replicate API |
| **openrag** | Langflow | Single-command RAG platform (Langflow + Docling + OpenSearch) |
| **autoresearch** | Karpathy | Autonomous experiment loop — agent iterates, evaluates, keeps improvements |
| **mwp** | MWP Paper | Model Workspace Protocol — framework-free AI agent orchestration via filesystem + markdown I/O contracts |

### SEO & GEO — AI Search Optimization (12 skills + 5 agents)

| Skill | What It Does |
|-------|-------------|
| **geo** | Main orchestrator — `/geo audit <url>` for full GEO + SEO audit |
| **geo-audit** | Full audit orchestration & composite scoring (0-100) |
| **geo-citability** | AI citation readiness scoring (optimal 134-167 word passages) |
| **geo-crawlers** | Check robots.txt for 14+ AI crawlers |
| **geo-llmstxt** | Analyze/generate llms.txt standard file |
| **geo-brand-mentions** | Brand presence on AI-cited platforms (YouTube, Reddit, Wikipedia) |
| **geo-platform-optimizer** | Platform-specific AI search optimization |
| **geo-schema** | Structured data (JSON-LD) for AI discoverability |
| **geo-technical** | Technical SEO foundations |
| **geo-content** | Content quality & E-E-A-T assessment |
| **geo-report** | Client-ready markdown GEO report |
| **geo-report-pdf** | Professional PDF with charts and gauges |

### Security (Trail of Bits — 50+ skills)

| Skill | What It Does |
|-------|-------------|
| **tob-semgrep** | Static analysis with Semgrep |
| **tob-semgrep-rule-creator** | Custom Semgrep rule creation |
| **tob-codeql** | GitHub CodeQL security scanning |
| **tob-audit-context-building** | Deep contextual security analysis |
| **tob-audit-prep-assistant** | Security audit preparation |
| **tob-supply-chain-risk-auditor** | Dependency and supply chain risk |
| **tob-code-maturity-assessor** | Code quality and maturity scoring |
| **tob-coverage-analysis** | Test coverage analysis |
| **tob-modern-python** | Modern Python best practices |
| **tob-property-based-testing** | Property-based test generation |
| **tob-secure-workflow-guide** | Secure CI/CD workflows |
| **tob-variant-analysis** | Vulnerability variant detection |
| **tob-*** | 40+ more: fuzzing, crypto analysis, blockchain scanners, SARIF, YARA |

### Content & Social

| Skill | What It Does |
|-------|-------------|
| **typefully** | Schedule social posts (X, LinkedIn, Threads, Bluesky) |
| **x-posting** | X/Twitter API — search, post, engage |
| **blog-image-generator** | Gemini-powered image generation for content |
| **instagram-slides** | Blog-to-carousel pipeline for Instagram/LinkedIn |
| **talking-head** | AI avatar video generation (ElevenLabs + Fal) |
| **elevenlabs-calls** | AI phone calls via ElevenLabs + Telnyx/Twilio |
| **research** | Multi-source intelligence (Brave, Exa, X, NewsAPI, GNews, Google CSE) |
| **sanity-best-practices** | CMS best practices, GROQ queries |
| **content-modeling-best-practices** | Scalable content model design |
| **seo-aeo-best-practices** | SEO and answer engine optimization |
| **content-experimentation-best-practices** | Content A/B testing |

### Operations & Monitoring

| Skill | What It Does |
|-------|-------------|
| **site-health** | HTTP health checks for all infrastructure endpoints |
| **daily-review** | End-of-day pipeline review, KPI snapshot, next-day planning |
| **revenue-metrics** | Pipeline/revenue metrics from Supabase CRM |

### Business & Marketing

| Skill | What It Does |
|-------|-------------|
| **market-research** | Market sizing, PESTLE, SWOT, TAM/SAM/SOM |
| **competitive-landscape** | Porter's Five Forces, differentiation analysis |
| **pricing-strategy** | Pricing models, packaging, monetization |
| **launch-strategy** | Product launch planning, GTM |
| **sales-automator** | Cold email generation, follow-ups, proposals |
| **email-sequence** | Drip campaigns, lifecycle emails, automation |
| **content-marketer** | Content creation, SEO, omnichannel distribution |
| **brand-voice** | Brand guidelines, visual identity, tone/style |
| **seo-fundamentals** | E-E-A-T, Core Web Vitals, technical SEO |
| **linkedin-cli** | LinkedIn automation — profiles, search, messages, connections, posts |

### Engineering & Architecture

| Skill | What It Does |
|-------|-------------|
| **architect-review** | System architecture review, scalability, design patterns |
| **prompt-engineering** | LLM prompt optimization, agent debugging |
| **prd-generator** | Feature planning, product requirements documents |
| **postmortem-writing** | Incident reviews, root cause analysis |
| **escalation** | Engineering/product/leadership escalation templates |
| **excalidraw-diagrams** | Generate `.excalidraw` diagram files |

### External Integrations

| Skill | What It Does |
|-------|-------------|
| **deep-research** | Autonomous research via Google Gemini Deep Research Agent |
| **jules** | Delegate async coding tasks to Google Jules AI agent |
| **linear-claude-skill** | Linear issue management & team workflows |
| **csv-data-summarizer-claude-skill** | CSV analysis, stats, visualization |
| **qmd-sessions** | Convert Claude Code transcripts to searchable markdown |
| **cc-nano-banana** | Image generation via Gemini |
| **outline** | Outline wiki — search, read, manage, export |

---

## MCP Servers

All configured globally — available in every project, every session.

| Server | Purpose | Key Operations |
|--------|---------|---------------|
| **supabase** | Database | Queries, migrations, edge functions, branch management |
| **clickup** | Project Management | Tasks, comments, time tracking, documents |
| **playwright** | Browser Automation | Navigate, click, fill forms, screenshots, scrape |
| **context7** | Library Docs | Up-to-date documentation lookup for any library |
| **github** | Source Control | PRs, issues, commits, code search, releases |
| **google-workspace / gws** | Google Workspace | Docs, Drive, Sheets, Gmail, Calendar, comments |
| **google-sheets** | Spreadsheets | Read/write cells, formulas, batch updates, formatting |
| **n8n** | Workflow Automation | Create/edit/test workflows, templates, executions |
| **qmd** | Session Search | Semantic search over past Claude Code session transcripts |
| **heyreach** | LinkedIn Outreach | Campaign management, lead lists, messaging, webhooks |

---

## Custom Agents

### Development Agents

| Agent | What It Does |
|-------|-------------|
| **backend-engineer** | Backend architecture, API design, server-side logic |
| **frontend-engineer** | React/Next.js components, UI implementation |
| **frontend-developer** | Frontend development specialist |
| **fullstack-developer** | End-to-end engineering across frontend, backend, DB |
| **performance-engineer** | Profiling, optimization, bottleneck analysis |
| **designer** | UI/UX decisions, component layout, accessibility |
| **security-engineer** | Security audits, vulnerability assessment, auth patterns |
| **refactor-agent** | Code restructuring, pattern extraction, tech debt |
| **test-engineer** | Test suite management, coverage analysis, QA |
| **code-reviewer** | Security-focused code review with performance analysis |
| **code-simplifier** | Simplification-first refactoring — reduce complexity |
| **staff-reviewer** | Senior engineer perspective on code quality |
| **debugger** | General error/exception debugging |
| **error-detective** | Error analysis, log parsing, root cause diagnosis |
| **prompt-engineer** | Prompt optimization and debugging |
| **database-architect** | Schema design, query optimization, data modeling |
| **data-engineer** | Data pipelines, ETL, data infrastructure |
| **devops-engineer** | Infrastructure, CI/CD, deployment |
| **documentation-writer** | Technical documentation |

### Domain Agents

| Agent | What It Does |
|-------|-------------|
| **compliance-checker** | OpSec compliance validation for brand/legal requirements |
| **deal-reviewer** | Lower-middle-market M&A deal analysis |
| **email-verify-debugger** | KadenVerify email verification system debugging |
| **deploy-validator** | Deployment validation and infrastructure checks |

### GEO-SEO Agents (5)

| Agent | What It Does |
|-------|-------------|
| **geo-ai-visibility** | Citability, crawlers, llms.txt, brand mentions |
| **geo-platform-analysis** | Platform-specific optimization |
| **geo-technical** | Technical SEO analysis |
| **geo-content** | Content & E-E-A-T analysis |
| **geo-schema** | Schema markup analysis |

### GSD (Get Shit Done) Agents (12)

| Agent | Role |
|-------|------|
| **gsd-planner** | Creates phase execution plans |
| **gsd-executor** | Executes GSD workflow phases |
| **gsd-verifier** | Verifies work completion against goals |
| **gsd-debugger** | GSD-aware debugging with context |
| **gsd-codebase-mapper** | Maps project structure & dependencies |
| **gsd-phase-researcher** | Deep research for specific phases |
| **gsd-project-researcher** | Broad project context research |
| **gsd-research-synthesizer** | Synthesizes findings from multiple researchers |
| **gsd-roadmapper** | Generates project roadmaps |
| **gsd-plan-checker** | Validates plans before execution |
| **gsd-integration-checker** | Verifies cross-phase integration |
| **gsd-nyquist-auditor** | Sampling-based code quality audits |

---

## Slash Commands

### Core Commands

| Command | What It Does |
|---------|-------------|
| `/commit-push` | Commit with security scan + `Co-Authored-By` trailer, then push |
| `/quick-commit` | Fast commit & push (less thorough) |
| `/deploy` | Deployment validation workflow |
| `/grill` | Adversarial code review — harsh, production-focused |
| `/review-changes` | Review all uncommitted changes |
| `/test-and-fix` | Run tests, auto-fix failures |
| `/techdebt` | Identify technical debt in recent changes |
| `/worktree` | Create & manage git worktrees for parallel work |
| `/start` | Session initialization workflow |
| `/simplify` | Parallel agents for code quality, reuse, efficiency review |
| `/loop` | Schedule recurring tasks on interval |
| `/wrap-up` | End-of-session summary, commit session work, context handoff |
| `/rem-sleep` | Consolidate and defrag memory files |

### GSD Commands (30+)

Project lifecycle management:

```
/gsd:new-project       — Initialize a GSD project
/gsd:new-milestone     — Create milestone with phases
/gsd:add-phase         — Add workflow phase
/gsd:plan-phase        — Plan phase execution
/gsd:research-phase    — Deep research for a phase
/gsd:execute-phase     — Execute a planned phase
/gsd:validate-phase    — Validate phase completion
/gsd:verify-work       — Verify deliverables
/gsd:progress          — Show project progress
/gsd:health            — Project health check
/gsd:debug             — GSD-aware debugging
/gsd:map-codebase      — Map project structure
/gsd:audit-milestone   — Audit milestone quality
/gsd:check-todos       — List outstanding TODOs
/gsd:add-todo          — Add TODO item
/gsd:pause-work        — Pause project (save state)
/gsd:resume-work       — Resume paused project
/gsd:complete-milestone — Mark milestone done
/gsd:cleanup           — Clean up resources
/gsd:quick             — Fast task execution
/gsd:settings          — Configure GSD preferences
/gsd:help              — Full command reference
```

---

## CLI Tools

| Tool | Version | What It Does |
|------|---------|-------------|
| **RTK** (Rust Token Killer) | v0.27.2 | Compresses Bash output via PreToolUse hook — saves 60-90% tokens per session |
| **Playwright** | v1.58.2 | Browser automation CLI — codegen, screenshots, test recording, PDF generation |
| **QMD** | — | Indexes Claude Code session transcripts for semantic search |
| **GWS CLI** | v0.8.0 | Google Workspace operations from the command line |
| **GSD** | — | 30+ meta-prompting commands for structured project execution |
| **linkedin-cli** | — | LinkedIn automation: profiles, search, messages, connections, Sales Navigator |

---

## Hooks & Automation

### PreToolUse (runs before every tool call)
- **RTK auto-rewrite**: Bash commands routed through RTK for token compression

### PostToolUse (runs after every tool call)
- **Auto-format**: Ruff (Python), Prettier (JS/TS/JSON/CSS/MD/YAML) — code is always formatted
- **GSD context monitor**: Tracks project state changes

### SessionStart
- **GSD update checker**: Checks for GSD system updates

### Stop (session end reminder)
4-point checklist:
1. Lint/tests passing?
2. All changes trace to request?
3. Did you check `/toolkit-scout`?
4. Have you written learnings to memory?

---

## Reference Resources (`apps/_resources/`)

| Resource | Best For |
|----------|---------|
| **awesome-llm-apps** | Agent patterns, RAG, browser automation |
| **system-design** | Sharding, rate limiting, message brokers |
| **design-patterns-typescript** | Strategy, Command, Observer patterns |
| **awesome-devops** | IaC, monitoring, CI/CD tools |
| **papers-we-love** | Distributed systems theory |
| **claude-skills** | 169 ready-made skills (9 categories) |
| **skill-builder** | Creating well-structured skills |
| **noeai-free-claude-code** | Skill examples, agent workflow patterns |
| **paperclip** | AI agent orchestration architecture |
| **anthropic-courses** | Prompt engineering, tool use, API fundamentals |

---

## Setup Guide

### Prerequisites
- Claude Code CLI installed
- Node.js 18+
- Python 3.10+

### 1. Install Plugin Packs

In Claude Code, enable plugins via settings or install individually:

```
superpowers, financial-analysis, investment-banking, private-equity,
apollo-pack, ai-skills, claude-mem, pair-programmer, document-skills,
pm-product-discovery, pm-product-strategy, pm-execution,
pm-market-research, pm-data-analytics, pm-go-to-market,
pm-marketing-growth, pm-toolkit
```

### 2. Install CLI Tools

```bash
# RTK (Rust Token Killer)
cargo install rtk-cli

# QMD (Session Search)
# See: https://github.com/nicobailey/qmd

# GWS CLI
npm install -g @nicobailey/gws-cli
```

### 3. Configure MCP Servers

Add to `~/.claude.json` under `mcpServers`:

```json
{
  "supabase": { "command": "npx", "args": ["-y", "@supabase/mcp-server"] },
  "playwright": { "command": "npx", "args": ["@anthropic-ai/mcp-playwright"] },
  "github": { "command": "npx", "args": ["@anthropic-ai/mcp-github"] },
  "context7": { "command": "npx", "args": ["@anthropic-ai/mcp-context7"] },
  "google-sheets": { "command": "npx", "args": ["@anthropic-ai/mcp-google-sheets"] },
  "n8n": { "command": "npx", "args": ["@anthropic-ai/mcp-n8n"] },
  "clickup": { "command": "npx", "args": ["@anthropic-ai/mcp-clickup"] },
  "heyreach": { "command": "npx", "args": ["@anthropic-ai/mcp-heyreach"] }
}
```

### 4. Install Skills, Agents, Commands, and GSD

```bash
# From the cloned repo:
./install.sh

# Or manually:
cp -R skills/* ~/.claude/skills/
cp agents/*.md ~/.claude/agents/
cp commands/*.md ~/.claude/commands/
cp -R commands/gsd ~/.claude/commands/gsd
cp -R gsd ~/.claude/get-shit-done
```

### 5. Configure Hooks

Add to `~/.claude/settings.json`:

```json
{
  "hooks": {
    "PreToolUse": [{ "matcher": "Bash", "hooks": [{ "command": "rtk rewrite" }] }],
    "PostToolUse": [
      { "matcher": "Edit|Write", "hooks": [
        { "command": "ruff format --quiet $FILE 2>/dev/null || true" },
        { "command": "prettier --write $FILE 2>/dev/null || true" }
      ]}
    ]
  }
}
```

---

## Architecture

### Repo Structure (what you're installing)

```
claude-toolkit-catalog/
├── skills/              ← 212 custom skills (each with SKILL.md + optional scripts)
│   ├── toolkit-scout/   ← Mandatory pre-task scanner
│   ├── geo/             ← GEO-SEO audit orchestrator
│   ├── geo-*/           ← 11 GEO sub-skills
│   ├── openrag/         ← RAG platform skill
│   ├── autoresearch/    ← Karpathy's experiment loop
│   ├── mwp/             ← Model Workspace Protocol methodology
│   ├── tob-*/           ← 50+ Trail of Bits security skills
│   └── ...              ← 140+ more skills
├── agents/              ← 40 custom agents
│   ├── code-reviewer.md
│   ├── deal-reviewer.md
│   ├── geo-*.md         ← 5 GEO subagents
│   ├── gsd-*.md         ← 12 GSD pipeline agents
│   └── ...
├── commands/            ← 43 slash commands
│   ├── commit-push.md
│   ├── grill.md
│   ├── gsd/             ← 34 GSD commands
│   │   ├── new-project.md
│   │   ├── execute-phase.md
│   │   └── ...
│   └── ...
├── gsd/                 ← GSD pipeline system (96 files)
│   ├── bin/             ← CLI tools (gsd-tools.cjs + lib/)
│   ├── workflows/       ← Orchestration workflows
│   ├── templates/       ← Plan, summary, context templates
│   └── references/      ← Checkpoints, TDD, git patterns
├── install.sh           ← One-command installer
└── README.md
```

### Where it installs

```
~/.claude/
├── settings.json        ← Permissions, hooks, plugins
├── CLAUDE.md            ← Global instructions (loaded every session)
├── skills/              ← ← skills/ copied here
├── agents/              ← ← agents/ copied here
├── commands/            ← ← commands/ copied here
├── get-shit-done/       ← ← gsd/ copied here
└── projects/
    └── */memory/        ← Per-project persistent memory

~/.claude.json           ← MCP server configurations
```

---

## Mandatory Workflow Rules

1. **Toolkit-scout first** — Always invoke `/toolkit-scout` before any non-trivial task. Don't build what already exists.
2. **Memory write** — Every session must write learnings to `memory/MEMORY.md` before closing.
3. **Use existing tools** — Check scripts, skills, MCP servers, and CLI tools before creating new ones.

---

*Last updated: 2026-03-12*

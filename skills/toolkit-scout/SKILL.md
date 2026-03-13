---
name: toolkit-scout
description: MANDATORY before any non-trivial task, plan mode entry, or building anything new. Scans all available resources — 205+ skills, 35 agents, 10 plugin packs, 9 MCP servers, 70+ scripts, CLI tools, API keys, and reference repos. Fires automatically; no user prompt needed.
---

# Toolkit Scout

## Overview

Before building or planning ANYTHING, scan this inventory. The system has 205+ custom skills, 35 agents, 10 plugin packs, 9 MCP servers, 70+ scripts, 4 CLI tools, and 12 reference repos. Most tasks can be partially or fully solved with what already exists.

## When to Use

- **ALWAYS** before starting any non-trivial task (this is mandatory, not optional)
- Entering plan mode for a multi-step task
- Before writing a new script, tool, or automation
- When unsure what resources are available
- Before installing any new package or service

## Discovery Checklist

Scan all sections. Present only what's relevant to the current task.

### 1. Slash Commands (`~/.claude/commands/`)

| Command | Trigger |
|---|---|
| `/commit-push` | Saving and pushing work |
| `/quick-commit` | Checkpointing without push |
| `/review-changes` | Reviewing diffs |
| `/grill` | Adversarial code review |
| `/test-and-fix` | Failing tests |
| `/techdebt` | End-of-session cleanup |
| `/deploy` | Pushing to servers |
| `/worktree` | Parallel sessions |
| `/start` | Session initialization |
| `/boris` | Claude Code workflow tips (43 tips) |
| `/simplify` | Parallel agents for code quality review |
| `/loop` | Schedule recurring tasks on interval |
| `/wrap-up` | End-of-session summary, commit session work, context handoff |
| `/rem-sleep` | Consolidate and defrag memory files |

#### GSD Commands (`~/.claude/commands/gsd/`)

30+ commands for structured project execution. Key ones: `/gsd:new-project`, `/gsd:plan-phase`, `/gsd:execute-phase`, `/gsd:progress`, `/gsd:debug`, `/gsd:quick`, `/gsd:resume-work`, `/gsd:map-codebase`. Run `/gsd:help` for full list.

### 2. Custom Agents (`~/.claude/agents/`)

#### Business & Domain
| Agent | When it applies |
|---|---|
| `deal-reviewer` | Evaluating CIMs, teasers, inbound deals |
| `compliance-checker` | Social profiles, financial language, BBB |

#### Engineering
| Agent | When it applies |
|---|---|
| `backend-engineer` | Backend architecture, API design, server-side logic |
| `frontend-engineer` | React/Next.js components, UI implementation |
| `frontend-developer` | Frontend development (alternative to frontend-engineer) |
| `fullstack-developer` | End-to-end application development |
| `performance-engineer` | Profiling, optimization, bottleneck analysis |
| `designer` | UI/UX decisions, component layout, accessibility |
| `security-engineer` | Security audits, vulnerability assessment, auth patterns |
| `refactor-agent` | Code restructuring, pattern extraction, tech debt |
| `test-engineer` | Test strategy, automation, coverage analysis |
| `code-reviewer` | Code quality, security, maintainability review |
| `code-simplifier` | Reducing complexity, removing dead code |
| `staff-reviewer` | Thorough staff-engineer-level code review |
| `database-architect` | Database design, data modeling, scalability |
| `data-engineer` | Data pipelines, ETL, data infrastructure |
| `devops-engineer` | Infrastructure, CI/CD, deployment |
| `prompt-engineer` | Prompt optimization for LLMs and AI systems |
| `documentation-writer` | Technical documentation |
| `error-detective` | Log analysis, error pattern detection |
| `debugger` | Debugging errors, test failures, unexpected behavior |

#### Operations
| Agent | When it applies |
|---|---|
| `deploy-validator` | Post-deployment health checks |
| `email-verify-debugger` | KadenVerify issues |

#### GSD Pipeline (13 agents)
`gsd-planner`, `gsd-executor`, `gsd-verifier`, `gsd-debugger`, `gsd-phase-researcher`, `gsd-project-researcher`, `gsd-research-synthesizer`, `gsd-roadmapper`, `gsd-codebase-mapper`, `gsd-plan-checker`, `gsd-integration-checker`, `gsd-nyquist-auditor`

### 3. Custom Skills by Domain (`~/.claude/skills/` — 179 skills)

#### Frontend & UI
| Skill | Source | What it does |
|---|---|---|
| `nextjs` | SummonAI Kit | Next.js App Router, SSR, routing, middleware |
| `next-best-practices` | Vercel | Official Next.js patterns and conventions |
| `next-cache-components` | Vercel | Caching strategies and cache-aware components |
| `next-upgrade` | Vercel | Next.js version upgrade workflows |
| `react` | SummonAI Kit | React components, hooks, state management |
| `react-best-practices` | Vercel | Official React patterns and optimization |
| `composition-patterns` | Vercel | React component composition and reuse |
| `typescript` | SummonAI Kit | TypeScript types, generics, strict config |
| `frontend-design` | Anthropic | Bold UI design, typography, color systems |
| `web-design-guidelines` | Vercel | Web design standards compliance |
| `remotion` | Remotion | Programmatic video creation with React |

#### Backend & API
| Skill | Source | What it does |
|---|---|---|
| `python` | SummonAI Kit | Python development, async, testing |
| `fastapi` | SummonAI Kit | FastAPI routes, services, database integration |
| `stripe-best-practices` | Stripe | Payment integration patterns |
| `upgrade-stripe` | Stripe | Stripe SDK/API version upgrades |
| `better-auth-*` | Better Auth | Authentication (5 skills: best-practices, create-auth, email/password, org, 2FA) |

#### Database
| Skill | Source | What it does |
|---|---|---|
| `supabase` | SummonAI Kit | Client setup, RLS, migrations, Edge Functions |
| `supabase-postgres-best-practices` | Supabase (official) | PostgreSQL performance optimization |
| `postgres` | Community | PostgreSQL patterns |

#### Browser Automation
| Skill | Source | What it does |
|---|---|---|
| `playwright` | SummonAI Kit | Playwright testing, selectors, CI config |
| `stagehand` | SummonAI Kit | AI-driven browser automation |

#### Cloud & Infrastructure
| Skill | Source | What it does |
|---|---|---|
| `cloudflare-agents-sdk` | Cloudflare | Stateful AI agents with scheduling, RPC, MCP |
| `cloudflare-building-ai-agent` | Cloudflare | AI agents with state and WebSockets |
| `cloudflare-durable-objects` | Cloudflare | Stateful coordination with SQLite |
| `cloudflare-web-perf` | Cloudflare | Core Web Vitals auditing |
| `cloudflare-wrangler` | Cloudflare | Workers, KV, R2, D1, Queues deployment |
| `terraform-*` | HashiCorp | 6 skills: code gen, modules, style, stacks, imports, Azure |
| `composio` | Composio | Connect to 1000+ SaaS apps with managed auth |
| `expo-*` | Expo | 9 skills: deployment, CI/CD, API routes, SwiftUI, Jetpack, Tailwind |

#### Financial & Data
| Skill | Source | What it does |
|---|---|---|
| `edgartools` | K-Dense-AI | SEC EDGAR financial data and regulatory filings |
| `alpha-vantage` | K-Dense-AI | Market data and financial time series |
| `fred-economic-data` | K-Dense-AI | Federal Reserve economic indicators |
| `usfiscaldata` | K-Dense-AI | US fiscal and treasury data |
| `denario` | K-Dense-AI | Financial calculations and modeling |
| `hedgefundmonitor` | K-Dense-AI | Hedge fund tracking and analysis |
| `timesfm-forecasting` | K-Dense-AI | Time series forecasting |
| `statistical-analysis` | K-Dense-AI | Statistical modeling and hypothesis testing |
| `exploratory-data-analysis` | K-Dense-AI | EDA workflows and visualization |
| `polars` | K-Dense-AI | High-performance dataframes |
| `dask` | K-Dense-AI | Parallel computing for large datasets |
| `market-research-reports` | K-Dense-AI | Market research generation |

#### AI & ML
| Skill | Source | What it does |
|---|---|---|
| `claude-agent-sdk` | SummonAI Kit | Claude Agent SDK, multi-agent orchestration |
| `gemini-api-dev` | Google | Gemini API development |
| `gemini-interactions-api` | Google | Gemini interactions and conversations |
| `gemini-live-api-dev` | Google | Gemini Live API real-time interactions |
| `vertex-ai-api-dev` | Google | Vertex AI platform development |
| `hf-cli` | HuggingFace | HF Hub CLI for models, datasets, repos |
| `hugging-face-datasets` | HuggingFace | Dataset creation and management |
| `hugging-face-model-trainer` | HuggingFace | Model training with TRL (SFT, DPO, GRPO) |
| `hugging-face-evaluation` | HuggingFace | Model evaluation workflows |
| `hugging-face-jobs` | HuggingFace | Compute jobs on HF infrastructure |
| `hugging-face-trackio` | HuggingFace | ML experiment tracking |
| `huggingface-gradio` | HuggingFace | Gradio UI for ML demos |
| `hf-mcp` | HuggingFace | HuggingFace MCP server integration |
| `hugging-face-*` | HuggingFace | +3 more: dataset-viewer, paper-publisher, tool-builder |
| `replicate` | Replicate | Run AI models via Replicate API |
| `openrag` | Langflow | Single-command RAG platform (Langflow + Docling + OpenSearch) |
| `autoresearch` | Karpathy | Autonomous experiment loop — agent iterates, evaluates, keeps improvements |
| `mwp` | MWP Paper | Model Workspace Protocol — framework-free AI agent orchestration via filesystem + markdown I/O contracts |

#### Security (Trail of Bits — 50+ skills)
| Skill | What it does |
|---|---|
| `tob-semgrep` | Static analysis with Semgrep |
| `tob-semgrep-rule-creator` | Custom Semgrep rule creation |
| `tob-codeql` | GitHub CodeQL security scanning |
| `tob-audit-context-building` | Deep contextual security analysis |
| `tob-audit-prep-assistant` | Security audit preparation |
| `tob-supply-chain-risk-auditor` | Dependency and supply chain risk |
| `tob-code-maturity-assessor` | Code quality and maturity scoring |
| `tob-coverage-analysis` | Test coverage analysis |
| `tob-modern-python` | Modern Python best practices |
| `tob-property-based-testing` | Property-based test generation |
| `tob-secure-workflow-guide` | Secure CI/CD workflows |
| `tob-variant-analysis` | Vulnerability variant detection |
| `tob-*` | 40+ more: fuzzing, crypto analysis, blockchain scanners, SARIF, YARA |

#### Content & Social
| Skill | Source | What it does |
|---|---|---|
| `typefully` | Typefully | Schedule social posts (X, LinkedIn, Threads, Bluesky) |
| `sanity-best-practices` | Sanity | CMS best practices, GROQ queries |
| `content-modeling-best-practices` | Sanity | Scalable content model design |
| `seo-aeo-best-practices` | Sanity | SEO and answer engine optimization |
| `content-experimentation-best-practices` | Sanity | Content A/B testing |

#### Operations & Monitoring (Felix)
| Skill | What it does |
|---|---|
| `site-health` | HTTP health checks for all Kadenwood/Mundi infrastructure |
| `daily-review` | End-of-day pipeline review, KPI snapshot, next-day planning |
| `revenue-metrics` | Pipeline/revenue metrics from Supabase CRM (+ Stripe when ready) |
| `coding-agent-loops` | Persistent tmux coding sessions with retry loops |
| `cron-guide` | Reference for scheduling recurring tasks and heartbeats |

#### Content & Social (Felix)
| Skill | What it does |
|---|---|
| `research` | Multi-source intelligence (Brave, Exa, X, NewsAPI, GNews, Google CSE) |
| `x-posting` | X/Twitter API — search, post, engage |
| `blog-image-generator` | Gemini-powered image generation for content |
| `instagram-slides` | Blog-to-carousel pipeline for Instagram/LinkedIn |
| `talking-head` | AI avatar video generation (ElevenLabs + Fal) |
| `elevenlabs-calls` | AI phone calls via ElevenLabs + Telnyx/Twilio |

#### Business & Marketing
`brand-voice`, `escalation`, `market-research`, `competitive-landscape`, `email-sequence`, `sales-automator`, `pricing-strategy`, `launch-strategy`, `content-marketer`, `seo-fundamentals`, `linkedin-cli`

#### SEO & GEO (AI Search Optimization — 12 skills + 5 agents)
| Skill | What it does |
|---|---|
| `geo` | Main orchestrator — `/geo audit <url>` for full GEO + SEO audit |
| `geo-audit` | Full audit orchestration & composite scoring (0-100) |
| `geo-citability` | AI citation readiness scoring (optimal 134-167 word passages) |
| `geo-crawlers` | Check robots.txt for 14+ AI crawlers |
| `geo-llmstxt` | Analyze/generate llms.txt standard file |
| `geo-brand-mentions` | Brand presence on AI-cited platforms (YouTube, Reddit, Wikipedia) |
| `geo-platform-optimizer` | Platform-specific AI search optimization |
| `geo-schema` | Structured data (JSON-LD) for AI discoverability |
| `geo-technical` | Technical SEO foundations |
| `geo-content` | Content quality & E-E-A-T assessment |
| `geo-report` | Client-ready markdown GEO report |
| `geo-report-pdf` | Professional PDF with charts and gauges |

#### Dev Workflow
`architect-review`, `postmortem-writing`, `prompt-engineering`, `prd-generator`, `excalidraw-diagrams`, `rem-sleep`, `qmd-sessions`, `toolkit-scout`, `wrap-up`, `mwp` (I/O contracts for agent pipelines)

### 4. Plugin Packs (10 packs, 300+ skills)

| Pack | Domain |
|---|---|
| **Superpowers** | TDD, debugging, brainstorming, code review, plan execution, git worktrees |
| **Financial Analysis** | 3-statements, DCF, LBO, comps, competitive analysis, deck QC |
| **Investment Banking** | CIM, teaser, one-pager, buyer list, merger model, process letter, pitch deck |
| **Private Equity** | IC memo, DD checklist, deal screening, portfolio review, returns, value creation |
| **Apollo Pack** | 25+ skills for Apollo.io API, sequences, rate limits, webhooks |
| **Document Skills** | PDF, PPTX, DOCX, XLSX, frontend design, web artifacts, MCP builder |
| **AI Skills** | Google Workspace, Imagen, Jules, deep-research, ElevenLabs, Manus, databases |
| **PM Skills** | 65 skills: discovery, strategy, execution, market research, analytics, GTM, marketing |
| **Claude-Mem** | Cross-session memory, smart search, phased plans |
| **Pair Programmer** | Real-time screen/audio capture, pair programming |

### 5. MCP Servers (live integrations)

| Server | Use for |
|---|---|
| `supabase` | Database queries, migrations, edge functions |
| `clickup` | Tasks, comments, time tracking, docs |
| `playwright` | Browser automation, screenshots, scraping |
| `context7` | Up-to-date library documentation |
| `github` | PRs, issues, commits, code search |
| `google-workspace` / `gws` | Docs, Drive, folders, comments |
| `google-sheets` | Spreadsheet read/write, formulas |
| `n8n` | Workflow automation, templates |
| `qmd` | Semantic search over session transcripts |
| `heyreach` | LinkedIn outreach campaigns |

### 6. CLI Tools

| Tool | What it does |
|---|---|
| `rtk` | Token compression proxy — 60-90% savings (auto via hook) |
| `linkedin` | LinkedIn automation — profiles, search, messages, connections, Sales Navigator |
| `gws` | Google Workspace CLI — Drive, Gmail, Calendar, Sheets, Docs |
| `qmd` | Session transcript indexing + semantic search |

### 7. Existing Scripts (`scripts/`)

70+ scripts: Google Sheets/Docs, CRM sync, ClickUp, Apollo, Drive, deck generation, data imports, metrics, lead scraping. Run `ls scripts/ | grep -i <keyword>` to search.

### 8. API Keys (`config/api_keys.json`)

Keys configured for: LSEG, Orbis, A-Leads, Twitter/X, n8n, Supabase, Vercel, Gemini, FMP, Finnhub, Alpha Vantage, and others. Check before registering new services.

### 9. Reference Resources (`apps/_resources/`)

| Resource | Best for |
|---|---|
| `awesome-llm-apps` | Agent patterns, RAG, browser automation |
| `system-design` | Sharding, rate limiting, message brokers |
| `design-patterns-typescript` | Strategy, Command, Observer patterns |
| `awesome-devops` | IaC, monitoring, CI/CD tools |
| `papers-we-love` | Distributed systems theory |
| `claude-skills` | 169 ready-made skills (9 categories) |
| `skill-builder` | Creating well-structured skills |
| `noeai-free-claude-code` | Skill examples, agent workflow patterns |
| `paperclip` | AI agent orchestration architecture |
| `anthropic-courses` | Prompt engineering, tool use, API fundamentals |

### 10. App-Specific Resources

Each app in `apps/` has its own `CLAUDE.md` with domain context, test commands, and deployment details.

## Output Format

After scanning, present a brief table:

```
**Toolkit Scout Results**

| Resource | How it helps | Action |
|---|---|---|
| [specific resource] | [why it's relevant] | [use directly / adapt / reference] |
```

Only list resources that are actually relevant. Don't pad the list.

## Common Mistakes

- Writing a new script when `scripts/` has 70+ existing ones
- Building a browser scraper when Playwright MCP or stagehand skill is available
- Creating a new slash command when an existing one covers the use case
- Manually querying an API when an MCP server provides direct access
- Not checking reference resources before designing from scratch
- Building financial models from scratch when Financial Analysis / IB / PE packs have templates
- Writing custom LinkedIn automation when `linkedin-cli` is installed globally
- Not checking GSD commands before building project management workflows
- Ignoring Trail of Bits security skills when reviewing code security
- Building Supabase queries without checking `supabase-postgres-best-practices`
- Writing auth from scratch when Better Auth skills exist
- Not using official vendor skills (Vercel, Stripe, Cloudflare) for their platforms
- Building data pipelines without checking K-Dense-AI financial/data skills
- Creating ML workflows without checking HuggingFace skills
- Designing multi-stage agent pipelines without checking MWP skill for I/O contract patterns
- Fixing outputs directly instead of fixing the source instructions (edit-source principle)

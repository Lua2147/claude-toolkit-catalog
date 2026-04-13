---
name: toolkit-scout
description: MANDATORY before any non-trivial task, plan mode entry, or building anything new. Scans all available resources — 516 skills, 169 agents, 314 commands, 15 rules, 22 plugin packs, 9 MCP servers, 70+ scripts, CLI tools, API keys, and reference repos. Fires automatically; no user prompt needed.
---

# Toolkit Scout

## Overview

Before building or planning ANYTHING, scan this inventory. The system has 516 custom skills, 169 agents, 314 commands, 15 rules, 5 contexts, 7 CLAUDE.md templates, 22 plugin packs, 9 MCP servers, 70+ scripts, 6 CLI tools, and 12 reference repos. Most tasks can be partially or fully solved with what already exists.

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
| `/ship` | **Universal build SOP** — invokes `ship-software` skill (v3.0). 3 tracks (hotfix/small/full), parallel-by-default orchestration, review loops in every phase, iteration from "done" criteria |
| `/commit-push` | Saving and pushing work |
| `/quick-commit` | Checkpointing without push |
| `/review-changes` | Reviewing diffs |
| `/review` | Multi-mode ensemble review (code, architecture, security, plan, prompt, performance) |
| `/review:code` | Code review with auto-fix |
| `/review:security` | Security review (OWASP, secrets, dependencies) |
| `/review:architecture` | Architecture + deployment + docs review |
| `/review:plan` | Plan feasibility + documentation freshness |
| `/review:prompt` | Prompt structure + enforceability review |
| `/review:performance` | Performance profiling review |
| `/grill` | Quick adversarial code review |
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

#### Domain Commands (awesome-claude-code-toolkit)

| Category | Commands |
|---|---|
| `architecture/` | `/architecture:adr`, `/architecture:design-review`, `/architecture:diagram`, `/architecture:migrate`, `/architecture:plan`, `/architecture:refactor` |
| `devops/` | `/devops:ci-pipeline`, `/devops:deploy`, `/devops:dockerfile`, `/devops:k8s-manifest`, `/devops:monitor` |
| `documentation/` | `/documentation:api-docs`, `/documentation:doc-gen`, `/documentation:memory-bank`, `/documentation:onboard`, `/documentation:update-codemap` |
| `git/` | `/git:changelog`, `/git:commit`, `/git:fix-issue`, `/git:pr-create`, `/git:pr-review`, `/git:release`, `/git:worktree` |
| `refactoring/` | `/refactoring:cleanup`, `/refactoring:dead-code`, `/refactoring:extract`, `/refactoring:rename`, `/refactoring:simplify` |
| `security/` | `/security:audit`, `/security:csp`, `/security:dependency-audit`, `/security:hardening`, `/security:secrets-scan` |
| `testing/` | `/testing:e2e`, `/testing:integration-test`, `/testing:snapshot-test`, `/testing:tdd`, `/testing:test-coverage`, `/testing:test-fix` |
| `workflow/` | `/workflow:checkpoint`, `/workflow:orchestrate`, `/workflow:wrap-up` |

#### GSD Commands (`~/.claude/commands/gsd/`)

30+ commands for structured project execution. Key ones: `/gsd:new-project`, `/gsd:plan-phase`, `/gsd:execute-phase`, `/gsd:progress`, `/gsd:debug`, `/gsd:quick`, `/gsd:resume-work`, `/gsd:map-codebase`. Run `/gsd:help` for full list.

#### Plugin Commands (awesome-claude-code-toolkit — 122 dirs, ~220 commands)

| Category | Plugins |
|---|---|
| **Frontend/UI** | `ui-designer`, `frontend-developer`, `responsive-designer`, `css-cleaner`, `color-contrast`, `accessibility-checker`, `screen-reader-tester`, `a11y-audit`, `visual-regression`, `bundle-analyzer` |
| **Backend/API** | `backend-architect`, `api-architect`, `api-tester`, `api-benchmarker`, `api-reference`, `openapi-expert`, `schema-designer`, `query-optimizer`, `database-optimizer`, `migrate-tool`, `migration-generator` |
| **Testing** | `test-writer`, `unit-test-generator`, `test-data-generator`, `test-results-analyzer`, `e2e-runner`, `mutation-tester`, `contract-tester`, `load-tester` |
| **DevOps/Infra** | `deploy-pilot`, `docker-helper`, `k8s-helper`, `helm-charts`, `terraform-helper`, `aws-helper`, `azure-helper`, `gcp-helper`, `ci-debugger`, `monitoring-setup`, `infrastructure-maintainer` |
| **Code Quality** | `code-guardian`, `code-review-assistant`, `code-explainer`, `code-architect`, `codebase-documenter`, `complexity-reducer`, `dead-code-finder`, `import-organizer`, `double-check`, `refactor-engine` |
| **Git/PR/Release** | `smart-commit`, `commit-commands`, `changelog-writer`, `changelog-gen`, `pr-reviewer`, `fix-pr`, `fix-github-issue`, `release-manager`, `update-branch`, `git-flow`, `create-worktrees` |
| **Documentation** | `doc-forge`, `readme-generator`, `adr-writer`, `onboarding-guide` |
| **Project Mgmt** | `plan`, `sprint-prioritizer`, `explore`, `discuss`, `linear-helper`, `github-issue-manager` |
| **AI/ML** | `ai-prompt-lab`, `rag-builder`, `embedding-manager`, `model-evaluator`, `prompt-optimizer`, `model-context-protocol`, `ultrathink`, `vision-specialist` |
| **Performance** | `optimize`, `perf-profiler`, `performance-monitor`, `memory-profiler`, `lighthouse-runner` |
| **Security** | `security-guidance`, `compliance-checker`, `data-privacy`, `license-checker` |
| **Mobile** | `flutter-mobile`, `react-native-dev`, `ios-developer`, `android-developer`, `desktop-app` |
| **Specialized** | `seed-generator`, `regex-builder`, `cron-scheduler`, `env-manager`, `env-sync`, `n8n-workflow`, `debug-session`, `bug-detective`, `dependency-manager`, `monorepo-manager`, `type-migrator`, `context7-docs`, `feature-dev`, `product-shipper`, `web-dev`, `content-creator`, `technical-sales`, `slack-notifier`, `analytics-reporter`, `experiment-tracker`, `finance-tracker`, `workflow-optimizer`, `tool-evaluator`, `python-expert`, `rapid-prototyper` |

Each plugin has 1-3 slash commands (e.g., `/ui-designer:implement-design`, `/docker-helper:build-image`, `/docker-helper:optimize-dockerfile`).

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

#### Language Specialists (awesome-claude-code-toolkit — 25 agents)
`assembly-expert`, `c-expert`, `cpp-expert`, `csharp-expert`, `dart-expert`, `elixir-expert`, `go-expert`, `haskell-expert`, `java-expert`, `julia-expert`, `kotlin-expert`, `lua-expert`, `nim-expert`, `objective-c-expert`, `perl-expert`, `php-expert`, `python-expert`, `r-expert`, `ruby-expert`, `rust-expert`, `scala-expert`, `swift-expert`, `typescript-expert`, `zig-expert`, `clojure-expert`

#### Infrastructure (awesome-claude-code-toolkit — 12 agents)
`ansible-engineer`, `aws-architect`, `azure-architect`, `cloud-migration`, `docker-specialist`, `gcp-architect`, `kubernetes-engineer`, `linux-admin`, `network-engineer`, `terraform-engineer`, `ci-cd-specialist`, `site-reliability`

#### AI/ML (awesome-claude-code-toolkit — 8 agents)
`ai-ethics-advisor`, `computer-vision`, `data-scientist`, `ml-engineer`, `ml-ops`, `nlp-specialist`, `recommendation-systems`, `reinforcement-learning`

#### Business/Product (awesome-claude-code-toolkit — 9 agents)
`business-analyst`, `product-manager`, `scrum-master`, `technical-writer`, `ux-designer`, `ux-researcher`, `content-strategist`, `accessibility-specialist`, `localization-expert`

#### Research (awesome-claude-code-toolkit — 10 agents)
`academic-researcher`, `code-archaeologist`, `competitive-analyst`, `compliance-analyst`, `incident-responder`, `patent-analyst`, `regulatory-analyst`, `threat-modeler`, `security-researcher`, `vulnerability-analyst`

#### Specialized (awesome-claude-code-toolkit — 14+ agents)
`api-designer`, `blockchain-developer`, `compiler-engineer`, `embedded-systems`, `game-developer`, `graphics-programmer`, `iot-architect`, `low-level-optimizer`, `mobile-developer`, `real-time-systems`, `systems-programmer`, `ui-animator`, `webgl-specialist`, `hardware-interface`

#### Orchestration (awesome-claude-code-toolkit — 6 agents)
`meta-orchestrator`, `parallel-executor`, `pipeline-architect`, `quality-gate`, `resource-optimizer`, `task-decomposer`

#### GSD Pipeline (13 agents)
`gsd-planner`, `gsd-executor`, `gsd-verifier`, `gsd-debugger`, `gsd-phase-researcher`, `gsd-project-researcher`, `gsd-research-synthesizer`, `gsd-roadmapper`, `gsd-codebase-mapper`, `gsd-plan-checker`, `gsd-integration-checker`, `gsd-nyquist-auditor`

### 3. Custom Skills by Domain (`~/.claude/skills/` — 516 skills)

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
| `agent-harness-construction` | ECC | Design and optimize agent action spaces, tool definitions, observation formatting |
| `enterprise-agent-ops` | ECC | Long-lived agent workload operations, observability, lifecycle management |
| `cost-aware-llm-pipeline` | ECC | LLM cost optimization — model routing, budget tracking, prompt caching |
| `fal-ai-media` | ECC | Unified media generation via fal.ai — image, video, audio |

#### Engineering Patterns (awesome-claude-code-toolkit — 34 skills)
| Skill | What it does |
|---|---|
| `accessibility-wcag` | WCAG compliance and accessibility |
| `api-design-patterns` | API architecture and design patterns |
| `authentication-patterns` | Auth implementation patterns |
| `aws-cloud-patterns` | AWS architecture and services |
| `ci-cd-pipelines` | CI/CD pipeline design |
| `continuous-learning` | Progressive learning patterns |
| `data-engineering` | Data pipeline design |
| `database-optimization` | Query and schema optimization |
| `design-system` | Component library architecture |
| `devops-automation` | Infrastructure automation |
| `django-patterns` | Django best practices |
| `docker-best-practices` | Container optimization |
| `frontend-excellence` | Advanced frontend patterns |
| `git-advanced` | Advanced git workflows |
| `golang-idioms` | Go language patterns |
| `graphql-design` | GraphQL schema and resolvers |
| `kubernetes-operations` | K8s operations and debugging |
| `llm-integration` | LLM API integration patterns |
| `mcp-development` | MCP server development |
| `microservices-design` | Microservices architecture |
| `mobile-development` | Mobile app patterns |
| `monitoring-observability` | Observability stack design |
| `nextjs-mastery` | Advanced Next.js patterns |
| `performance-optimization` | Performance tuning |
| `postgres-optimization` | PostgreSQL tuning |
| `python-best-practices` | Python idioms and patterns |
| `react-patterns` | Advanced React patterns |
| `redis-patterns` | Redis data structure patterns |
| `rust-systems` | Rust systems programming |
| `security-hardening` | Application security hardening |
| `springboot-patterns` | Spring Boot best practices |
| `tdd-mastery` | Test-driven development |
| `testing-strategies` | Test strategy design |
| `typescript-advanced` | Advanced TypeScript |
| `websocket-realtime` | WebSocket and real-time patterns |

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
| `continuous-learning-v2` | Instinct-based learning — hooks observe sessions, evolves into skills/commands/agents |
| `eval-harness` | Formal evaluation framework for Claude Code sessions (eval-driven development) |
| `strategic-compact` | Smart `/compact` timing at phase boundaries to preserve context |
| `verification-loop` | Comprehensive verification system for Claude Code session outputs |
| `iterative-retrieval` | Progressive context retrieval — solves the subagent context problem |
| `dmux-workflows` | Multi-agent orchestration via dmux (parallel tmux agent sessions) |
| `automation-mcp` | macOS desktop control — mouse, keyboard, screenshots, window management via MCP |
| `cron-guide` | Reference for scheduling recurring tasks and heartbeats |

#### Content & Social (Felix)
| Skill | What it does |
|---|---|
| `research` | Multi-source intelligence (Brave, Exa, X, NewsAPI, GNews, Google CSE) |
| `x-posting` | X/Twitter API v2 — post, threads, media upload, search, analytics, rate limits |
| `fal-ai-media` | Unified media generation via fal.ai — image, video, audio |
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

#### Claude Certified Architect Exam Prep (10 skills covering all 5 domains)
| Skill | Domain | Covers |
|---|---|---|
| `agentic-orchestration-patterns` | D1 (27%) | Fork sessions, escalation protocols, state persistence, hook lifecycle |
| `tool-design-patterns` | D2 (18%) | Tool descriptions, error responses, tool_choice modes, built-in tools |
| `claude-code-ci` | D3 (20%) | CI/CD integration, non-interactive mode, PR automation |
| `claude-code-config-advanced` | D3 (20%) | Glob rules, plan mode decisions, iterative refinement |
| `structured-extraction` | D4 (20%) | Few-shot extraction, validation-retry loops |
| `message-batches-api` | D4 (20%) | Batch processing 10K+ items at 50% cost |
| `ensemble-review` | D4 (20%) | Multi-instance review, majority vote aggregation |
| `confidence-calibration` | D4/D5 | Confidence scoring, routing, calibration anchors |
| `context-reliability` | D5 (15%) | Summarization traps, lost-in-middle, persistent facts |
| `information-provenance` | D5 (15%) | Claim-source mappings, escalation triggers, exploration protocol |

#### Dev Workflow
`ship-software` (v3.0 — universal build SOP, parallel-by-default orchestration, review loops in every phase, "done" criteria-driven iteration), `architect-review`, `review` (7-mode ensemble review with 110+ tools), `postmortem-writing`, `prompt-engineering`, `prd-generator`, `excalidraw-diagrams`, `rem-sleep`, `qmd-sessions`, `toolkit-scout`, `wrap-up`, `mwp` (I/O contracts for agent pipelines)

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
| `playwright` | Browser automation CLI — codegen, screenshots, test recording, PDF generation |
| `linkedin` | LinkedIn automation — profiles, search, messages, connections, Sales Navigator |
| `gws` | Google Workspace CLI — Drive, Gmail, Calendar, Sheets, Docs |
| `qmd` | Session transcript indexing + semantic search |

### 6b. Python Scraping & Browser Automation Libraries

| Library | Version | What it does | Import |
|---|---|---|---|
| `scrapling` | 0.4.2 | Stealth HTTP fetcher — `Fetcher` (Chrome impersonation), `StealthyFetcher` (Cloudflare bypass), `PlayWrightFetcher` (full browser). Use `page.body.decode()` NOT `page.text` | `from scrapling.fetchers import Fetcher, StealthyFetcher` |
| `crawlee` | 1.6.0 | Playwright-based crawler with auto link following, request queuing, `enqueueLinksByClickingElements`. Full SPA crawling with network interception | `from crawlee.crawlers import PlaywrightCrawler` |
| `camoufox` | installed | Firefox-based stealth browser — anti-fingerprinting, humanized cursor movement, geolocation spoofing | `import camoufox` |
| `browserforge` | installed | Browser fingerprint generation — realistic headers, TLS fingerprints, navigator properties | `import browserforge` |
| `parsel` | installed | CSS/XPath selector engine (from Scrapy) — fast HTML parsing without full browser | `import parsel` |
| `playwright` | installed | Microsoft Playwright — browser automation, also available via MCP server | `from playwright.sync_api import sync_playwright` |

**When to use which:**
- **Quick API probing** → `scrapling.Fetcher` (fastest, Chrome impersonation, dict cookies)
- **Cloudflare-protected sites** → `scrapling.StealthyFetcher` (list cookies) or `camoufox`
- **Full SPA crawl with auto-discovery** → `crawlee.PlaywrightCrawler` (follows links, clicks elements, captures XHR)
- **Interactive browser + network capture** → Playwright MCP (`browser_navigate`, `browser_click`, `browser_network_requests`, `browser_run_code`)
- **HTML parsing only** → `parsel` (no browser needed)

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
- Building a browser scraper when Playwright MCP, stagehand, crawlee, scrapling, or camoufox is available
- Using `page.text` with scrapling Fetcher (returns TextHandler object) — use `page.body.decode()`
- Using dict cookies with StealthyFetcher (needs list[dict]) or list cookies with Fetcher (needs dict)
- Writing manual XHR capture loops when `crawlee.PlaywrightCrawler` auto-discovers pages + captures all network
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

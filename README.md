# Claude Code Toolkit Catalog

Our full Claude Code configuration — skills, plugins, agents, commands, MCP servers, and automation hooks. Everything listed here is available in every session.

## Quick Stats

| Category | Count |
|----------|-------|
| Plugin Packs | 24 (200+ skills) |
| Custom Skills | 50+ |
| MCP Servers | 9 |
| Custom Agents | 26 |
| Slash Commands | 40+ |
| Permission Rules | 50+ |

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
| **pptx** | anthropic-agent-skills | Generate & edit PowerPoint presentations |
| **docx** | anthropic-agent-skills | Create & edit Word documents |
| **pdf** | anthropic-agent-skills | Read, generate, and fill PDF forms |
| **xlsx** | anthropic-agent-skills | Excel spreadsheet operations |
| **web-artifacts-builder** | anthropic-agent-skills | Interactive web artifacts (HTML/CSS/JS) |
| **document-skills** | anthropic-agent-skills | Unified document operations across formats |
| **pair-programmer** | claude-code | Screen recording, audio capture, visual AI feedback |

### Domain Plugins

| Plugin | Provider | What It Does |
|--------|----------|-------------|
| **superpowers** | superpowers-dev | 40+ skills: planning, brainstorming, TDD, code review, worktrees, parallel agents |
| **financial-analysis** | financial-services-plugins | DCF, LBO, comps, 3-statement models, deck review |
| **investment-banking** | financial-services-plugins | CIM, buyer lists, merger models, process letters, teasers, one-pagers |
| **private-equity** | financial-services-plugins | DD checklists, IC memos, returns analysis, portfolio ops, value creation plans |
| **apollo-pack** | claude-code-plugins-plus | B2B company intelligence, API patterns, SDK integrations |
| **ai-skills** | ai-skills | AI/ML fundamentals, prompt engineering, model selection, integrations |

### Product Management Plugins

| Plugin | Provider | What It Does |
|--------|----------|-------------|
| **pm-product-discovery** | pm-skills | User research, brainstorming, assumption mapping, interview scripts |
| **pm-product-strategy** | pm-skills | Business models, PESTLE, Porter's Five Forces, lean canvas, pricing |
| **pm-execution** | pm-skills | PRDs, sprint planning, OKRs, release notes, stakeholder maps |
| **pm-market-research** | pm-skills | Market sizing, segments, personas, sentiment analysis, competitor analysis |
| **pm-data-analytics** | pm-skills | Cohort analysis, A/B testing, SQL queries |
| **pm-go-to-market** | pm-skills | GTM strategy, growth loops, ICPs, battlecards |
| **pm-marketing-growth** | pm-skills | North star metrics, positioning, product naming |
| **pm-toolkit** | pm-skills | NDAs, privacy policies, resume review, grammar check |

---

## Custom Skills

### Workflow & Meta

| Skill | What It Does |
|-------|-------------|
| **toolkit-scout** | Searches for existing tools, scripts, skills, MCP servers before you build something new. **Mandatory before any non-trivial task.** |
| **rem-sleep** | Consolidates and defrags memory files across sessions |
| **wrap-up** | End-of-session summary, context handoff, memory write |
| **insights** | Analyzes correction patterns and workflow efficiency |
| **scout** | Surfaces relevant context from claude-mem history |
| **boris** | 43 Claude Code workflow tips (parallel work, plan mode, hooks, worktrees) |
| **refine** | Self-scoring convergence loops — iterates until output quality plateaus |

### Business & Strategy

| Skill | What It Does |
|-------|-------------|
| **market-research** | Market sizing, PESTLE, SWOT, TAM/SAM/SOM |
| **competitive-landscape** | Porter's Five Forces, differentiation analysis |
| **pricing-strategy** | Pricing models, packaging, monetization |
| **launch-strategy** | Product launch planning, GTM, feature announcements |
| **sales-automator** | Cold email generation, follow-ups, proposals |
| **email-sequence** | Drip campaigns, lifecycle emails, automation |
| **content-marketer** | Content creation, SEO, omnichannel distribution |
| **brand-voice** | Brand guidelines, visual identity, tone/style guides |
| **seo-fundamentals** | E-E-A-T, Core Web Vitals, technical SEO |

### Engineering & Architecture

| Skill | What It Does |
|-------|-------------|
| **architect-review** | System architecture review, scalability, design patterns |
| **prompt-engineering** | LLM prompt optimization, agent debugging |
| **prd-generator** | Feature planning, product requirements documents |
| **postmortem-writing** | Incident reviews, root cause analysis, action items |
| **escalation** | Engineering/product/leadership escalation templates |
| **excalidraw-diagrams** | Generate `.excalidraw` diagram files |

### External Integrations

| Skill | What It Does |
|-------|-------------|
| **linkedin-cli** | LinkedIn automation — profiles, search, messages, connections, posts, Sales Navigator |
| **deep-research** | Autonomous research via Google Gemini Deep Research Agent |
| **jules** | Delegate async coding tasks to Google Jules AI agent |
| **postgres** | PostgreSQL read-only queries, schema exploration |
| **outline** | Outline wiki — search, read, manage, export |
| **linear-claude-skill** | Linear issue management & team workflows |
| **csv-data-summarizer-claude-skill** | CSV analysis, stats, visualization |
| **qmd-sessions** | Convert Claude Code transcripts to searchable markdown |
| **cc-nano-banana** | Image generation via Gemini |

---

## MCP Servers

All configured globally — available in every project, every session.

| Server | Purpose | Key Operations |
|--------|---------|---------------|
| **supabase** | Database | Queries, migrations, edge functions, branch management |
| **clickup** | Project Management | Tasks, comments, time tracking, documents, chat |
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
| **code-reviewer** | Security-focused code review with performance analysis |
| **code-simplifier** | Simplification-first refactoring — reduce complexity |
| **frontend-developer** | React/TypeScript/Tailwind specialist |
| **fullstack-developer** | End-to-end engineering across frontend, backend, DB |
| **test-engineer** | Test suite management, coverage analysis, QA |
| **staff-reviewer** | Senior engineer perspective on code quality |
| **debugger** | General error/exception debugging |
| **error-detective** | Error analysis, log parsing, root cause diagnosis |
| **prompt-engineer** | Prompt optimization and debugging |
| **database-architect** | Schema design, query optimization, data modeling |

### Domain Agents

| Agent | What It Does |
|-------|-------------|
| **compliance-checker** | OpSec compliance validation for our brand/legal requirements |
| **deal-reviewer** | Lower-middle-market M&A deal analysis |
| **email-verify-debugger** | KadenVerify email verification system debugging |
| **deploy-validator** | Deployment validation and infrastructure checks |

### GSD (Get Shit Done) Agents

A meta-workflow system with 12 specialized agents for structured project execution:

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
/gsd:settings          — Configure GSD preferences
/gsd:help              — Full command reference
```

---

## CLI Tools

| Tool | Version | What It Does |
|------|---------|-------------|
| **RTK** (Rust Token Killer) | v0.27.2 | Compresses Bash output via PreToolUse hook — saves 60-90% tokens per session |
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
  "clickup": { "command": "npx", "args": ["@anthropic-ai/mcp-clickup"] }
}
```

### 4. Copy Skills, Agents, and Commands

```bash
# Skills go in ~/.claude/skills/
# Agents go in ~/.claude/agents/
# Commands go in ~/.claude/commands/
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

```
~/.claude/
├── settings.json        ← Permissions, hooks, plugins
├── CLAUDE.md            ← Global instructions (loaded every session)
├── RTK.md               ← RTK usage guide (loaded every session)
├── skills/              ← 50+ custom skills
│   ├── toolkit-scout/
│   ├── rem-sleep/
│   ├── brand-voice/
│   └── ...
├── agents/              ← 26 custom agents
│   ├── code-reviewer.md
│   ├── deal-reviewer.md
│   ├── gsd-planner.md
│   └── ...
├── commands/            ← 40+ slash commands
│   ├── commit-push.md
│   ├── grill.md
│   ├── gsd/
│   │   ├── new-project.md
│   │   ├── execute-phase.md
│   │   └── ...
│   └── ...
└── projects/
    └── */memory/        ← Per-project persistent memory
        └── MEMORY.md

~/.claude.json           ← MCP server configurations
```

---

## Mandatory Workflow Rules

1. **Toolkit-scout first** — Always invoke `/toolkit-scout` before any non-trivial task. Don't build what already exists.
2. **Memory write** — Every session must write learnings to `memory/MEMORY.md` before closing.
3. **Use existing tools** — Check scripts, skills, MCP servers, and CLI tools before creating new ones.

---

*Last updated: 2026-03-09*

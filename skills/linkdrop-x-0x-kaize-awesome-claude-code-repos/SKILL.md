---
name: linkdrop-x-0x-kaize-awesome-claude-code-repos
description: Pointer to hesreallyhim/awesome-claude-code — the canonical community curation of Claude Code skills, agents, hooks, slash-commands, plugins, statuslines, and MCP servers (39,800+ stars, actively maintained). Use to discover community solutions before building new Claude Code tooling from scratch.
source: https://x.com/0x_kaize/status/2045580955759309131 → https://github.com/hesreallyhim/awesome-claude-code
allowed-tools: Read, Write, Edit, Bash, WebFetch, Glob, Grep
---

# linkdrop-x-0x-kaize — Awesome Claude Code

## Overview

`hesreallyhim/awesome-claude-code` (39,800+ stars, updated daily) is the canonical community-curated index of Claude Code resources. Skills, agents, hooks, slash-commands, plugins, statuslines, workflows — if a community solution exists for a CC workflow problem, it's cataloged here.

The author's thesis (@0x_kaize): most CC users never discover this list and end up rebuilding patterns that already exist. This skill exists so the agent consults the community layer before composing a new solution.

**Local-first principle:** this pairs with `toolkit-scout` (which scans your 1,100+ local skills). Toolkit-scout covers the local layer; this skill covers the community layer one hop beyond that. Run toolkit-scout FIRST.

## The canonical list

- **Repo**: https://github.com/hesreallyhim/awesome-claude-code (MIT-like awesome-list license)
- **39,800+ stars** as of 2026-04-20 — heavily vetted, actively curated
- **Updated daily** — new entries in "Latest Additions" at the top

## Real categories (from the live README)

| Category | What's in it |
|---|---|
| **Agent Skills** | Topic-organized skill definitions ready to drop into `~/.claude/skills/` |
| **Workflows & Knowledge Guides** | General / Teams / Ralph Wiggum sub-sections |
| **Tooling** | General, IDE Integrations, Usage Monitors, Orchestrators, Config Managers |
| **Status Lines** | Custom statusline implementations (rate pace, token burn, etc.) |
| **Hooks** | Pre/post-tool, Stop, UserPromptSubmit, SessionStart hooks |
| **Slash-Commands** | General, Version Control & Git, Code Analysis & Testing, Context Loading & Priming, Documentation & Changelogs, CI / Deployment, Project & Task Management, Miscellaneous |
| **CLAUDE.md Files** | Language-Specific / Domain-Specific / Project Scaffolding & MCP |
| **Alternative Clients** | Non-terminal CC clients |
| **Official Documentation** | Anthropic's canonical docs |

The README is ~45 KB and updated faster than any static mirror. Always pull it live rather than cache a snapshot here.

## Workflow — community-before-build

**Step 1 — Local layer first** (always):
```bash
# Check what already exists locally
cat ~/.claude/skills/toolkit-scout/SKILL.md
bash ~/.claude/scripts/route.sh "<your task>" --top=5
```

**Step 2 — If local miss, pull the awesome-claude-code README:**
```bash
gh api repos/hesreallyhim/awesome-claude-code/readme --jq '.content' | base64 -d > /tmp/acc-readme.md

# Scan the section that matches your need:
grep -A 20 "^## Hooks" /tmp/acc-readme.md                # for hooks
grep -A 30 "^## Slash-Commands" /tmp/acc-readme.md       # for slash commands
grep -A 20 "^### IDE Integrations" /tmp/acc-readme.md    # etc.
```

**Step 3 — Evaluate a candidate entry (trust gate):**
```bash
gh repo view <owner>/<repo> --json pushedAt,stargazerCount,licenseInfo,description

# Halt if: last push > 90 days, fewer than 10 stars, missing license, unclear description.
```

**Step 4 — Security pre-install scan** (mandatory for any community repo):
```bash
mkdir -p ~/sandbox/<repo> && cd ~/sandbox/<repo>
gh repo clone <owner>/<repo> .

# Banned-term + secret scans (our local validators)
bash ~/.claude/scripts/phase3/check-secrets.sh .
bash ~/.claude/scripts/phase3/check-gbrain-ban.sh .

# Hooks deserve extra scrutiny — they run shell commands
find . -name '*.sh' -o -name 'hooks.json' | xargs grep -l 'curl\|wget\|nc ' || echo "no network hooks"
```

**Step 5 — Integrate additively, never overwrite:**
Copy individual patterns into `~/.claude/skills/linkdrop-community-<source>-<item>/` — never install whole packs globally without trust review. Whole-pack installs bypass our security gates.

**Step 6 — Log what you imported:**
Add an entry to `docs/knowledge-base/wiki/02-workflow-and-dx/linkdrop-x-0x-kaize-awesome-claude-code-repos.md` (or a new KB file) under "Community tools evaluated" — what you took, from where, with trust-gate notes.

## When to use

- Starting any non-trivial Claude Code build and `toolkit-scout` returned thin local results.
- Evaluating "is there an existing hook / slash-command / plugin for X?" before writing one.
- Onboarding a new engineer to the CC ecosystem after they've read local CLAUDE.md.
- Auditing a `.claude/` setup — compare against community-canonical patterns.
- Building a curation list or "starter kit" for a new sub-team.

**Do NOT use when:**
- The problem is domain-specific (deal origination, PB / CapIQ data pipelines) — awesome-claude-code is horizontal, not domain.
- You need vetted-for-security tools — community repos require your own trust review every time.

## Gotchas

- **Trust is NOT transitive.** A repo linked from awesome-claude-code is curated for popularity or utility, not for safety. Always run the security scan.
- **Plugin rot** is faster than skill rot. Prefer extracting individual patterns to installing whole packs.
- **GitHub API rate limit**: `gh search repos` is 30/min unauthenticated, 5000/hr authenticated. If you're authenticated via `gh auth login`, you're fine.
- **License compliance** per `~/.claude/rules/dependency-management.md`: MIT / Apache-2.0 / BSD / ISC accepted; GPL / AGPL / SSPL flagged for legal review before use.
- **Overlap with local**: many community skills duplicate patterns already in your 1,100+ local inventory. Running `toolkit-scout` FIRST is not optional.

## Setup / Prerequisites

- `gh` CLI authenticated (`gh auth status`).
- Local sandbox dir (`~/sandbox/` — not tracked in main git).
- `~/.claude/scripts/phase3/` validators present: `check-secrets.sh`, `check-gbrain-ban.sh`, `check-skill-density.sh`.
- Familiarity with the local skill format: frontmatter + Overview + When to use + Workflow + density-script compliance.

## Output contract

When invoked with a specific category (e.g., "find a hook for auto-commit"), return:

```yaml
category: hooks
candidates:
  - repo: <owner>/<repo>
    stars: N
    last_push: YYYY-MM-DD
    license: MIT
    path_in_repo: <relative/path/to/pattern>
    trust_gate: pass | review | reject
recommendation: <which to import, with one-line rationale>
security_scan:
  banned_terms: pass | fail
  secrets: pass | fail
  network_hooks: none | <list>
```

## Source

- Tweet: https://x.com/0x_kaize/status/2045580955759309131 (2026-04-18, @0x_kaize)
- Canonical index: https://github.com/hesreallyhim/awesome-claude-code (39,800+ stars, MIT)
- Captured: 2026-04-18 via link-drop-pipeline; rewritten 2026-04-20 to replace the fabricated "10 repos table" with real category structure from the live README.

## Cross-references

- `toolkit-scout` — MUST run before this skill (local-first principle).
- `saraev-cc-claude-code-plugin-discovery` — plugin install UX.
- `anthropic-claude-code-best-practices-linkdrop` — Anthropic's official guidance.
- `~/.claude/rules/dependency-management.md` — license + vulnerability rules.
- `~/.claude/scripts/phase3/check-secrets.sh` — mandatory pre-import secret scan.
- `docs/knowledge-base/wiki/02-workflow-and-dx/INDEX.md` — local workflow KB.

## Related KB entry

- `docs/knowledge-base/wiki/02-workflow-and-dx/linkdrop-x-0x-kaize-awesome-claude-code-repos.md` — narrative version, trust-gate protocol, past community imports.

## Link-drop Additions

(Reserved — append idempotently when same author drops new threads.)

---
name: ship-software
description: Universal SOP for building and shipping software with agentic AI. Clarity-first, build fast, iterate from usage. 3 tracks, parallel-by-default orchestration, review loops in every phase.
---

# Ship Software SOP v3.0

The standard operating procedure for building and shipping software with Claude Code.

## Philosophy

Execution is near-free with agentic AI. The bottleneck is **knowing what to build**, not building it. Invest in clarity (what does "done" look like?), build fast in parallel, review at every phase, iterate from real usage.

**Not** "move fast and break things." **Not** exhaustive pre-analysis. The optimal loop: **define done clearly, plan densely, build in parallel, review each phase, fix what breaks, ship.**

## Prerequisites

**Install the full Claude Code toolkit before using this SOP:**
```bash
# Clone the toolkit catalog
git clone https://github.com/Lua2147/claude-toolkit-catalog.git
# Follow the README for installation of skills, plugins, agents, commands, MCP servers, and hooks
```
This gives you: 350+ skills, 168 agents, 300+ commands, 15 rules, 9 MCP servers, CLI tools (RTK, Playwright, QMD, GWS), and automation hooks. The SOP references these tools throughout — install first.

## Quick Reference

```
ENTRY POINT ROUTING (ask first, always)
  "Something broke and I know the fix"           -> Track 1: HOTFIX
  "A contained feature, script, or enhancement"   -> Track 2: SMALL BUILD
  "Multi-system, unknown scope, or multiple agents" -> Track 3: FULL BUILD

TRACK 3 DEFAULT: Orchestration mode.
  1 orchestrator session + N workers in worktrees.
  All non-dependent tasks run in parallel.
```

---

## Step 0: Pick Your Track

Route based on what you're actually doing:

| Signal | Track |
|--------|-------|
| Something broke, I know the fix | **Track 1: Hotfix** (<30 min) |
| Contained feature, script, enhancement | **Track 2: Small Build** (30min-2h) |
| Multi-system, unknown scope, needs agents | **Track 3: Full Build** (2h+) |

You can always **escalate** from a lower track to a higher one. You can never downgrade.

**Scope creep guard:** If scope grows mid-work, STOP and re-route to the appropriate track. Don't silently absorb complexity.

---

## Track 1: Hotfix

Something is broken and you know the fix. No planning needed.

1. Write the fix
2. Write or update tests — they must pass
3. Review: `/review:code` — auto-fixes mechanical issues, flags blockers
4. Commit with explicit file paths -> deploy

Still requires: tests pass, `/review:code` passes with zero blockers. No exceptions.

---

## Track 2: Small Build

A contained feature, script, or enhancement. 30 minutes to 2 hours.

### Scout (2 min)
Run `/toolkit-scout` — check if it already exists or can be composed from existing tools. If 90%+ exists, compose don't build.

### Build -> Review -> Iterate
1. **Context**: Stuff everything relevant into context — files, docs, examples
2. **Build**: Write the obvious approach. Don't deliberate between options — just build it.
3. **Review**: Run tests + `/review:code` + `/review:security`
4. **Fix**: Fix what the review found. Test again.
5. **Iterate**: Repeat until tests pass and review is clean.

Use `/btw` for side questions during build without breaking flow.
Use `/branch` to fork and try an alternative approach without losing progress.

### Ship
Commit with explicit file paths (never `git add -A`) -> deploy.

---

## Track 3: Full Build

Multi-system work, unknown scope, or anything requiring multiple agents.

**Default mode is orchestration:** 1 orchestrator session + N workers in worktrees. All non-dependent tasks run in parallel.

---

### Phase 1: Discover

Find what already exists before building anything.

1. Run `/toolkit-scout` — scan existing tools, skills, agents, scripts, MCP servers, reference resources
2. Search QMD for prior work: `mcp__qmd__deep_search("your problem domain")`
3. Assess coverage:
   - **90%+**: SKIP the build — compose from existing tools
   - **70-90%**: COMPOSE — extend existing tools to cover the gap
   - **30-70%**: EXTEND — significant new work building on existing foundation
   - **<30%**: BUILD — new system from scratch
4. Front-load context: gather every file, doc, and reference the agents will need

Output: coverage decision + context package.

---

### Phase 2: Brainstorm

Invoke `superpowers:brainstorming` skill.

Natural conversation exploring the problem and approaches. The brainstorm MUST produce:

**Explicit "done" criteria (3-5 acceptance criteria, written down).** This is the contract between you and the agents. Examples:
- "API returns paginated results with cursor-based pagination"
- "All 7 workers can run independently and report status to orchestrator"
- "Dashboard loads in under 2 seconds with 10K rows"

These are not vague goals. They are testable statements. If you can't write a test or verification command for it, it's not concrete enough.

**Agent decomposition** (if orchestration mode): identify the workers, their responsibilities, and what's independent vs dependent.

**Scope creep check**: "Has scope grown beyond original track? If yes, acknowledge and adjust."

Output: approved design with explicit acceptance criteria. **User gate — APPROVED / REVISE / REJECT.**

---

### Phase 3: Plan

Invoke `superpowers:writing-plans` skill.

The plan is the agent's brain. Make it dense. Every task in the plan must specify:

| Field | Required | Purpose |
|-------|----------|---------|
| Task description | Yes | What to build |
| Acceptance criteria | Yes | What "done" looks like (from brainstorm) |
| Verification command | Yes | How to prove it works |
| Worker assignment | Yes | Which agent owns this |
| Worktree name | Yes | Isolated workspace for this worker |
| Dependencies | Yes | What must complete before this starts (blockedBy) |
| Produces | If applicable | What this task outputs that other tasks consume |
| Consumes | If applicable | What this task needs from other tasks |

**Dependency graph and parallel groups.** The orchestrator must identify:
1. Which tasks have no mutual dependencies (run in parallel)
2. Which tasks depend on others (run after dependencies complete)
3. Group tasks into parallel execution waves:

```
Wave 1 (parallel): [Task A, Task B, Task C] — no dependencies
Wave 2 (parallel): [Task D, Task E] — D needs A, E needs B
Wave 3 (sequential): [Task F] — needs D and E
```

**Rule: All non-dependent tasks run in parallel. Every task runs in its own worktree.**

**Plan review:** Run `/review:plan`. This runs the review loop, catches real issues, takes 5 minutes. Not an ensemble consensus ceremony — a sanity check that the plan makes sense.

**Plan carefully for these exceptions** (invest extra analysis time):
- Database migrations — can corrupt data, hard to reverse
- External API integrations — rate limits, auth, discovery-first
- Multi-agent concurrency — shared resources, race conditions
- Auth/payment flows — security implications
- Production infrastructure changes — blast radius

Everything else: plan it, review it, build it.

Output: execution-ready plan with parallel groups. **User gate — APPROVED / REVISE / REJECT.**

---

### Phase 4: Build

The orchestrator manages the build. Every wave follows the same cycle:

```
Dispatch wave -> Workers build in worktrees -> Review output -> Fix -> Merge -> Next wave
```

#### Orchestrator Responsibilities

The orchestrator is a **dedicated session** that:

1. **Prepares worker prompts** — each worker gets:
   - Their tasks from the plan (acceptance criteria, verification commands)
   - Exact file paths and worktree/branch name
   - I/O contracts (what they consume, what they produce)
   - Rules and constraints specific to their task
   - Use `prompt-engineering` skill for worker prompts

2. **Dispatches workers into worktrees:**
   ```bash
   claude --worktree          # Built-in worktree isolation
   claude -w                  # Short form
   claude --worktree my-name  # Named worktree
   ```

3. **Monitors workers** via `/loop`:
   ```
   /loop 5m /babysit     — check worktree status, report drift
   ```

4. **Reviews each wave's output before merging** — this is where the review loop lives
5. **Merges** — orchestrator decides merge order, resolves conflicts
6. **Dispatches next wave** — only after previous wave is reviewed and merged

#### The Review Loop (every wave)

After each wave's workers complete:

1. Review worker output — does it meet the acceptance criteria?
2. Run `/review:code` on each worker's changes
3. Run tests on each worker's branch
4. Fix issues (orchestrator fixes or sends back to worker)
5. Merge clean branches into main build branch
6. Run full test suite on merged result
7. Proceed to next wave only when this wave is clean

**Review is not a phase — it's embedded in every build cycle.** Bugs caught per-wave are cheaper than bugs caught at the end.

#### Worker Rules

- Workers execute independently. They do NOT coordinate with each other — only with the orchestrator.
- Each worker runs in its own worktree. No shared mutable state.
- Workers self-verify against their acceptance criteria before reporting done.
- If a worker is blocked, it stops and reports to orchestrator. No guessing.

#### Continuous Commits

Work is never more than 15 minutes from being committed. Workers commit per-task. Orchestrator can run auto-commit via `/loop`:
```
/loop 15m /auto-save     — commit tracked changes in all worktrees
```

#### If Something Goes Sideways

STOP. Switch to plan mode. Re-plan that section. Do NOT keep pushing a failing approach.

---

### Phase 5: Test Against "Done"

After all waves are built, reviewed, and merged:

1. Run the full test suite on the merged result
2. Test each acceptance criterion from brainstorm — explicitly, one by one
3. What passes? Ship it.
4. What fails? Fix it. Test again. Repeat.

```
Test against "done" criteria ->
  All pass? -> Phase 6: Ship
  Some fail? -> Fix what broke -> Test again -> repeat
```

This is the iteration loop. The plan defines what "done" is. This loop gets you there.

#### Final Review

Run the review battery proportional to what you're shipping:

| Review | Always | If auth/API/data | If production deploy |
|--------|--------|-----------------|---------------------|
| Test suite | Yes | Yes | Yes |
| `/review:code` | Yes | Yes | Yes |
| `/review:security` | | Yes | Yes |
| `/review:performance` | | | Yes |
| `/review` (full) | | | Yes |
| `code-reviewer` agent | | | Yes |

The full battery is for production deploys to real users. Internal tools and scripts get code + security review.

---

### Phase 6: Ship

1. Merge into target branch
2. Run full test suite on merged branch
3. Deploy to target environment
4. Post-deploy health check
5. Use `/loop /babysit` to shepherd PR if needed:
   - Auto-address review comments
   - Auto-rebase when behind
   - Auto-fix CI failures
6. Commit with explicit file paths — never `git add -A`

---

### Phase 7: Close

Every build ends with a retrospective. This is not optional.

**4 retrospective questions:**
1. What phase was the bottleneck?
2. What did we learn from building/usage that planning didn't catch?
3. What should go in CLAUDE.md for next time?
4. What should change in this SOP?

**If the retrospective identifies an SOP improvement:**
1. Write the proposed edit
2. `/grill` the edit
3. Commit with `chore(sop):` prefix
4. Bump version in frontmatter

**Also:**
- Update project memory with decisions and learnings
- Clean up worktrees, branches, stale files
- Push to remote

---

## Principles

1. **Define "done" explicitly in brainstorm.** 3-5 testable acceptance criteria, written down. This is the contract.
2. **The plan is the agent's brain.** Dense: dependency graph, parallel groups, worker assignments, worktrees, I/O contracts. Structure, not ceremony.
3. **All non-dependent tasks run in parallel.** Orchestrator builds dependency graph, dispatches waves into worktrees.
4. **Every task in its own worktree.** Workers are isolated. Only the orchestrator merges.
5. **Review is continuous, not a gate.** Every build wave includes: build -> review -> fix -> merge. Not "build everything, then review everything."
6. **Build first, heavy-review after.** The full review battery runs on real code after a working version exists, not on hypothetical plans.
7. **Iterate from "done" criteria.** Build -> test against acceptance criteria -> fix what broke -> repeat until done.
8. **Plan carefully for: data, auth, concurrency, external APIs.** Everything else: build fast.
9. **Continuous commits.** Never more than 15 min from committed.
10. **If it goes sideways, re-plan immediately.** Don't keep pushing a failing approach.

---

## Tool & Skill Reference

Every tool and skill below is available in the toolkit. Install from [github.com/Lua2147/claude-toolkit-catalog](https://github.com/Lua2147/claude-toolkit-catalog) if not already set up.

### Discovery

| Tool/Skill | What It Does | When to Use |
|------------|------------------------------|-------------|
| `/toolkit-scout` | Scans your entire toolkit to find what already exists before you build anything | **MANDATORY** before any non-trivial task |
| `claude-mem:mem-search` | Searches past session decisions and learnings | When starting work in an area you've touched before |
| `explore:explore` / `explore:map` | Reads through a codebase to understand structure and key files | When working in an unfamiliar repo |

### Brainstorm

| Tool/Skill | What It Does | When to Use |
|------------|-------------|-------------|
| `superpowers:brainstorming` | Guides conversation to turn idea into design with explicit acceptance criteria | Start of every Track 3 build |
| `architecture:plan` | Architectural plan with component diagrams and dependency mapping | When multiple components need to fit together |
| `architecture:diagram` | Visual diagrams (C4, sequence, flow) | When you need to see component interactions |

### Plan

| Tool/Skill | What It Does | When to Use |
|------------|-------------|-------------|
| `superpowers:writing-plans` | Writes dense implementation plans with file paths, criteria, verification per task | **MANDATORY** for Track 3 |
| `prompt-engineering` | Crafts worker prompts with success criteria, verification commands, context, rules | **MANDATORY** for orchestration mode |
| `agentic-orchestration-patterns` | Patterns for parallel sessions, agent coordination, state persistence | **MANDATORY** for orchestration mode |
| `mwp` | I/O contracts between agents using filesystem structure and markdown | When workers produce outputs that other workers consume |
| `agent-harness-construction` | Optimize action space and tool definitions so agents succeed more often | When worker success rate is low |

### Plan Review

| Tool/Skill | What It Does | When to Use |
|------------|-------------|-------------|
| `/review:plan` | Review loop on the plan — catches structural issues, missing criteria, bad decomposition | **MANDATORY** after plan is written |

### Build

| Tool/Skill | What It Does | When to Use |
|------------|-------------|-------------|
| `superpowers:executing-plans` | Executes plan task-by-task with checkpoints and verification | Solo mode execution |
| `superpowers:dispatching-parallel-agents` | Launches multiple agents into worktrees for parallel execution | Orchestration mode — dispatch waves |
| `superpowers:using-git-worktrees` | Manages git worktrees: create, list, switch, merge, clean up | Any parallel work |
| `claude --worktree` / `claude -w` | **Built-in.** Launches Claude in its own worktree automatically | Default way to launch workers |
| `/btw` | Side query without breaking conversation flow | Quick questions during build |
| `/branch` | Fork session to try alternative approach without losing progress | When you want to experiment |

### Review (used in every build wave)

| Tool/Skill | What It Does | When to Use |
|------------|-------------|-------------|
| `/review:code` | Code quality, mechanical issues, auto-fixes | Every wave, every track |
| `/review:security` | Security vulnerabilities, secrets, auth issues | When touching auth, APIs, user data |
| `/review:performance` | Performance issues, N+1 queries, bundle size | Production deploys |
| `/review` (full) | All review modes combined | Final gate for production |
| `code-reviewer` agent | Fresh-eyes review from a dedicated agent | Final review pass |
| `/grill` | Adversarial review — tries to break your code | Additional signal. Can flag false positives. |
| `/simplify` | Finds overly complex code, suggests simpler alternatives | After reviews pass, before ship |
| `security:audit` / `security:secrets-scan` | Security vulnerabilities, hardcoded secrets | **MANDATORY** for auth, APIs, user data |

### Monitor

| Tool/Skill | What It Does | When to Use |
|------------|-------------|-------------|
| `/loop` | **Built-in.** Runs any command on a recurring interval | Primary monitoring — session-level |
| Custom watchdog crons (launchd) | Shell scripts on schedule via macOS launchd — survive session crashes | Infrastructure-level monitoring |
| `strategic-compact` | When to run `/compact` based on logical task boundaries | Long sessions approaching context limits |

### Ship

| Tool/Skill | What It Does | When to Use |
|------------|-------------|-------------|
| `superpowers:finishing-a-development-branch` | Final review, conflict resolution, merge strategy, branch cleanup | When build is verified and ready to merge |
| `git:pr-create` / `git:commit` | PRs and commits with conventional commit messages | Standard git workflow |
| `deploy` command | Deployment workflow for target environment | When merged and ready for production |

### Close

| Tool/Skill | What It Does | When to Use |
|------------|-------------|-------------|
| `wrap-up` | Summarizes accomplishments, flags loose ends, records to memory | **MANDATORY** at end of every session |
| `rem-sleep` | Consolidates and defrags memory files | When memory files are cluttered |
| `postmortem-writing` | Blameless postmortem with root cause analysis and action items | When something went wrong |

### Orchestration Architecture

| Resource | What It Does | When to Use |
|----------|-------------|-------------|
| `agentic-orchestration-patterns` | Patterns for forking context, parallel sessions, escalation, state persistence | Designing orchestration |
| `mwp` | I/O contracts between agents via markdown | Workers that share data |
| `agent-harness-construction` | Optimize agent action space and tool definitions | Improving worker success rate |
| `enterprise-agent-ops` | Running agents that stay alive for days/weeks | Production agent systems |
| `cost-aware-llm-pipeline` | Cost optimization — model routing, budget tracking, prompt caching | When token costs matter |

---

## Integration Summary

| Phase | Primary Skill | What It Produces |
|-------|--------------|-----------------|
| Discover | `/toolkit-scout` | Coverage assessment + context package |
| Brainstorm | `superpowers:brainstorming` | Approved design with explicit acceptance criteria |
| Plan | `superpowers:writing-plans` + `prompt-engineering` | Dense plan with parallel groups + worker prompts |
| Plan Review | `/review:plan` | Validated plan |
| Build (per wave) | `superpowers:dispatching-parallel-agents` | Built + reviewed + merged code |
| Test | Acceptance criteria verification | Pass/fail per criterion |
| Ship | `superpowers:finishing-a-development-branch` | Merged + deployed |
| Close | `wrap-up` + `rem-sleep` | Learnings captured |

The SOP tells you WHEN to invoke each skill. The skills tell you HOW.

---
name: review
description: >-
  Use when reviewing code changes, PRs, architecture, security, plans, prompts, or performance.
  7 modes: code, architecture, security, plan, prompt, performance, full.
  Ensemble consensus, auto-fix, escalation, scope drift detection.
---

# Review

## Modes

`/review` — runs full (all modes in parallel)
`/review:code` — code quality, tests, patterns
`/review:architecture` — structure, infra, deployment, docs
`/review:security` — OWASP, secrets, dependencies, attack surface
`/review:plan` — feasibility, completeness, documentation freshness
`/review:prompt` — XML structure, paths, context, enforceability
`/review:performance` — N+1, queries, bundle size, profiling

## Protocol

### 1. Scope

Determine what to review (priority order — use first match):
1. Explicit file args passed to `/review` → review those files
2. Uncommitted changes → `git diff`
3. Branch diff → `git diff origin/<base>`
4. Entire directory → if no changes and no args

If no changes detected and no files specified, report "No changes to review" and exit.

**Scope drift detection:** Compare files changed against stated intent (TODOS.md, PR description, commit messages). Output: `Scope: CLEAN | DRIFT | MISSING`.

### 2. Dispatch

**CRITICAL: Mode determines which tools to use. This is a HARD CONSTRAINT.**

1. Read [TOOLS.md](TOOLS.md) — find the section matching the selected mode
2. ONLY use tools from that mode's section. Do NOT use tools from other modes.
3. Always dispatch ALL ★-marked (default) tools for the mode
4. Add conditional tools based on what files are in the diff/scope
5. Each tool runs independently — do not let one tool's findings influence another
6. For `/review full`: dispatch ★ tools from ALL mode sections. Cap at 12 agents max.

If a tool fails or times out, log the failure and proceed with remaining tools. If fewer than 2 tools complete successfully, re-dispatch failed tools once.

### 3. Ensemble Consensus

After all tools return findings:
- **All agree** (same file, same line range ±5 lines, same issue type: security/style/correctness/performance/documentation) → auto-fix
- **Majority agree** → auto-fix, flag as majority-not-unanimous
- **Only one flags it** → hold for manual review, do not auto-fix
- **Contradiction** (one says "fix", another says "this is fine") → dispatch `tob-second-opinion` for tie-breaking

### 4. Fix-First Flow

Classify every finding:

**PR check first:** If reviewing a PR (`gh pr view` succeeds), report ALL fixes as suggestions only — do NOT modify the branch. Skip auto-fix.

**AUTO-FIX** (apply immediately, no approval — loop until clean):
- WARNING and NIT findings where ensemble agrees
- Mechanical fixes: imports, unused variables, formatting, path corrections
- Removing hardcoded secrets
- Documentation/comment fixes
- Renaming references (e.g., wrong tool name)

**ASK** (present to user ONLY for these):
- BLOCKER severity findings
- Changes that alter runtime behavior (adding validation, error handling, new code paths)
- Fixes outside the declared review scope

For each AUTO-FIX:
1. Apply the fix
2. Re-run the flagging tool on the fixed code
3. If fix passes → stage with `git add` (do NOT commit — user commits)
4. If fix fails → try alternate approach (max 2 attempts per finding)
5. If still fails → reclassify as ASK

**Max 5 fix-review cycles total.** After 5, report remaining and stop. The loop runs autonomously — do NOT ask the user for confirmation on AUTO-FIX items.

### 5. Verification of Claims

Before producing the final output:
- If you claim "this is safe" → cite the specific line proving safety
- If you claim "handled elsewhere" → read and cite the handling code
- If you claim "tests cover this" → name the test file and method
- Never say "likely handled" or "probably tested" — verify or flag as unknown

### 6. Severity Classification

- **BLOCKER** — prevents approval. Must fix. Shown first in report.
- **WARNING** — should fix. Auto-fixed if ensemble agrees.
- **NIT** — optional. Logged but not auto-fixed.

### 7. Escalation (False Positive Detection)

Track findings in `<project-root>/.claude/review-issues.md`. If file doesn't exist, create with header: `# Review Issues`.

- Finding appears **once** → normal fix
- Same finding appears **twice** → fix with different approach
- Same finding appears **3 times** → **ESCALATE** to `staff-reviewer`
  - Staff reviewer invokes `tob-fp-check` for verification
  - Rules: **REAL** (fix approach is wrong) or **FALSE POSITIVE** (dismiss permanently)
  - Decision recorded in `.claude/review-issues.md`

### 8. Documentation Staleness Check

For each doc file related to the reviewed files (not all repo docs):
- If code changes affect features described in that doc BUT the doc wasn't updated → flag as WARNING
- If TODOS.md or TODO.md exists, cross-reference: does this change close any TODOs?

### 9. Report

```
REVIEW COMPLETE — [mode]

Scope: [CLEAN | DRIFT | MISSING]

BLOCKERS: [N] — must fix before proceeding
  - [finding] — [file:line] — [what's wrong]

FIXED: [N] auto-fixed (staged, not committed)
  - [finding] — [what changed]

MANUAL: [N] need your input
  - [finding] (severity) — [options: A) fix B) skip]

DISMISSED: [N] false positives
  - [finding] — [reasoning]

STALE DOCS: [N]
  - [file] — [what changed that affects it]

NITS: [N]
  - [nit]

Cycles: [N]/5 | Tools used: [list]
```

### 10. Pattern Tracking

`.claude/review-issues.md` accumulates per project. Read before each run to skip known FPs and try proven fixes first.

## Integration

- **Ship Software SOP** — `/review` at every phase gate. Track 1: code. Track 2: code + security. Track 3: full.
- **Crash Recovery SOP** — `/review:plan` and `/review:prompt` validate recovery artifacts.
- **Orchestrator sessions** — `/review` on worker output before merge.

## Dogfooding

After writing or modifying this skill, run `/review:code` on itself once as validation.

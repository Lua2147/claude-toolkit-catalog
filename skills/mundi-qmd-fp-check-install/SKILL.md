---
name: mundi-qmd-fp-check-install
description: Mundi-specific integration layer for tob-fp-check — wires false-positive checking into Kadenwood / PitchBook / CapIQ / signal-validation review workflows so "fixed" findings don't retrigger across sessions. Use when running /mundi:security-audit, /mundi:refusal-test, validating intent-signal hits, or reviewing bug reports where recurrence needs suppression.
allowed-tools: Read, Write, Edit, Bash, Grep, Glob
---

# Mundi QMD — False-Positive Check Integration

## Overview

Thin integration pointer layer above `tob-fp-check`. The base tob skill provides the TRUE/FALSE-POSITIVE verdict protocol; this skill tells you **when + how to invoke it in Mundi-specific contexts** (Kadenwood CRM bugs, PB/CapIQ data-quality findings, signal hits, outreach bounces) so fixed findings don't retrigger session after session.

The problem this solves: same "issue" gets flagged in 4 consecutive review sessions because no session knows it was already dispositioned.

## When to use

- **Running `/mundi:security-audit`** — before flagging an issue, check if it was already dispositioned as FP.
- **Running `/mundi:refusal-test`** — same pattern; rationalization-to-reject table should include prior FPs.
- **Validating intent-signal hits** — "this company triggered the signal again" — check if we already decided it wasn't a real signal 30 days ago.
- **Bug triage in Kadenwood CRM** — email bounce / verification failure recurring → check FP log before opening a ticket.
- **PB/CapIQ data-quality reviews** — "this field looks wrong" — check if last review already said it's fine.

## When NOT to use

- Net-new findings that have zero prior context — just run `tob-fp-check` directly, no Mundi layer needed.
- Raw tob-fp-check is sufficient for most standalone reviews.

## The Mundi FP log pattern

**Location:** `docs/fp-log/` (monorepo root; create if missing)

**Structure:** one markdown file per domain — `kadenwood.md`, `pitchbook-data.md`, `capiq-data.md`, `intent-signals.md`, `outreach-bounces.md`.

**Entry format:**
```
## <finding-id> — <short title>
- **Date dispositioned:** YYYY-MM-DD
- **Session:** <qmd docid or conversation URL>
- **Verdict:** TRUE | FALSE-POSITIVE | NEEDS-MONITORING
- **Rationale:** <1-2 sentences>
- **Regression triggers:** <what would flip the verdict>
- **Hash signature:** <content hash of the finding for future match>
```

## Integration workflow

```
1. Review surfaces a finding
2. Hash the finding (normalize: strip dates, volatile IDs, keep semantic content)
3. Grep docs/fp-log/*.md for the hash → if found, check verdict
4. If FALSE-POSITIVE and no regression triggers hit → suppress, log "duplicate"
5. If TRUE or NEEDS-MONITORING → proceed with normal review
6. New finding → append to appropriate domain log after disposition
```

## Invocation

Inline-composition (not usually called directly; called by reviewers):

```python
# Inside /mundi:security-audit
findings = audit_scan()
for f in findings:
    verdict = Skill(skill="mundi-qmd-fp-check-install", {
      domain: "kadenwood",
      finding: f,
      mode: "check"  # or "log" to append new disposition
    })
    if verdict == "duplicate-fp":
        continue  # suppress
    # else proceed with ticket / fix
```

## I/O contract (MWP)

**state_reads:**
- `docs/fp-log/*.md` — per-domain logs
- `~/.claude/skills/tob-fp-check/SKILL.md` — base protocol

**state_writes:**
- `docs/fp-log/<domain>.md` — append new disposition entry

## Failure modes

| failure | recovery |
|---|---|
| FP log domain file missing | create with header + first entry |
| Hash collision (false match) | log entry includes full finding text for human verification |
| Stale regression triggers | if trigger hit, flip verdict + log re-disposition with new date |

## Cross-references

- **Base skill:** `~/.claude/skills/tob-fp-check/SKILL.md` (authoritative TRUE/FALSE-POSITIVE protocol — this skill DOES NOT replace it)
- **Invokers:** `/mundi:security-audit`, `/mundi:refusal-test`, origination signal review, CRM bug triage
- **Memory:** `feedback_no_parallel_scraping.md` (similar "decide once, don't re-decide" pattern)
- **KB:** `docs/knowledge-base/outputs/qmd-action-items-for-wave2.md` item #1

## Safety

- **Never auto-suppress without hash match + matching regression triggers.** A sloppy match = silencing a real problem.
- Log format is append-only. Past dispositions are preserved for audit.
- If in doubt, mark `NEEDS-MONITORING` and proceed with review — safer than false-suppressing.

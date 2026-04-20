---
name: mundi-qmd-secret-scan-precommit
description: Install + configure gitleaks (or trufflehog) as a mandatory pre-commit hook across Mundi Princeps repos, with Mundi-specific regex bundle (AIza, sk-ant-, gho_, Bearer, Twilio AC SID, "cookie" JSON field). Backfills patterns from ~/.claude/scripts/phase3/check-secrets.sh. Use when onboarding a new repo, a secret leak just happened, or pre-commit isn't yet wired.
allowed-tools: Read, Write, Edit, Bash, Grep, Glob
---

# Mundi QMD — Secret Scan Pre-Commit

## Overview

Prevents secret commits via automated pre-commit hooks. Addresses the root cause of the Twilio SID rsync leak and the legacy config.json exposure: secrets were caught **after** commit / **after** push, not before. PF-1 rotated the keys; this skill prevents recurrence.

Uses the existing Mundi secret-regex bundle from `~/.claude/scripts/phase3/check-secrets.sh` and wires it into `gitleaks` (preferred) or `trufflehog` via the `pre-commit` framework.

## When to use

- Onboarding a new monorepo or app (`apps/<new>/` just created)
- A secret just leaked — install the guardrail so it can't happen again
- Auditing an existing repo without pre-commit ("are we protected here?")
- Reviewing / updating the regex bundle as new providers are added

## The Mundi secret regex bundle

From `~/.claude/scripts/phase3/check-secrets.sh`:

```regex
# Google API keys (Gemini, GCP)
AIza[A-Za-z0-9_-]{35}

# Anthropic
sk-ant-api03-[A-Za-z0-9_-]{93}

# OpenAI
sk-[A-Za-z0-9]{20,}

# GitHub PATs
gho_[A-Za-z0-9]{36}
ghp_[A-Za-z0-9]{36}

# Bearer tokens (generic)
[Bb]earer\s+[A-Za-z0-9._~+/=-]+

# Twilio Account SID (the one that leaked)
AC[a-f0-9]{32}

# JSON cookie blocks
"cookie":\s*"[^"]+"

# AWS access keys
AKIA[0-9A-Z]{16}

# Vercel tokens
[A-Za-z0-9]{24}  # caution: needs context — too short for standalone match
```

## Install protocol

### Pre-commit framework (recommended)

```yaml
# .pre-commit-config.yaml
repos:
  - repo: https://github.com/gitleaks/gitleaks
    rev: v8.20.0
    hooks:
      - id: gitleaks
        args: ['--config=.gitleaks.toml']
```

### `.gitleaks.toml` — Mundi-specific

```toml
title = "Mundi Princeps secret rules"

[[rules]]
id = "google-api-key"
regex = '''AIza[A-Za-z0-9_-]{35}'''
description = "Google API key"

[[rules]]
id = "anthropic-key"
regex = '''sk-ant-api03-[A-Za-z0-9_-]{93}'''
description = "Anthropic API key"

[[rules]]
id = "github-pat"
regex = '''gho_[A-Za-z0-9]{36}|ghp_[A-Za-z0-9]{36}'''

[[rules]]
id = "twilio-account-sid"
regex = '''AC[a-f0-9]{32}'''
description = "Twilio Account SID (the one that leaked 2026-03)"

[[rules]]
id = "cookie-json"
regex = '''"cookie":\s*"[^"]+"'''

# Allowlist examples + redacted-placeholders
[allowlist]
regexes = [
  '\[REDACTED-ROTATED-[0-9]{4}-[0-9]{2}-[0-9]{2}\]',
  # Intentional test payload (structurally fake — won't match AIza regex):
  'AIza${FAKE_TEST_PAYLOAD_SUBSTITUTE_AT_RUNTIME}',
]
```

### Installation steps

```bash
cd <repo-root>

# Install pre-commit framework
pip install pre-commit   # or: brew install pre-commit

# Drop config files (from this skill's templates)
cp ~/.claude/skills/mundi-qmd-secret-scan-precommit/templates/.pre-commit-config.yaml .
cp ~/.claude/skills/mundi-qmd-secret-scan-precommit/templates/.gitleaks.toml .

# Install hooks
pre-commit install

# Backfill check — scan history once (prevents false-clean on already-leaked history)
gitleaks detect --config=.gitleaks.toml --verbose

# If history has secrets, note them (don't try to rewrite without git filter-repo + team coordination)
```

## Consuming-pattern alignment

If the existing `~/.claude/scripts/phase3/check-secrets.sh` gets new regexes, this skill's `.gitleaks.toml` template must be updated in sync. Maintenance rule:

```
~/.claude/scripts/phase3/check-secrets.sh  ←→  this skill's .gitleaks.toml
Changes propagate in both directions.
```

## Failure modes

| failure | recovery |
|---|---|
| pre-commit hook blocks commit legitimately (real secret) | DON'T bypass with --no-verify; move the secret out of the file, then commit |
| False positive on test fixture | add to `[allowlist]` in `.gitleaks.toml` with specific regex |
| New provider, new secret format | add rule + deploy update to all repos that have the skill |
| History has pre-skill secrets | git filter-repo + force-push + team coordination (don't skip history scan) |

## I/O contract (MWP)

**state_reads:**
- `~/.claude/scripts/phase3/check-secrets.sh` — source regex bundle
- `~/.claude/scripts/phase3/pre-rsync-achilles-grep.sh` — remote scan pattern (for sync contexts)
- `config/api_keys.json` — known legitimate secrets to allowlist if needed

**state_writes:**
- `<repo>/.pre-commit-config.yaml`
- `<repo>/.gitleaks.toml`
- `<repo>/.git/hooks/pre-commit` (installed by framework)

## Invocation

```bash
# Fresh install in a new repo
cd apps/new-app
Skill(skill="mundi-qmd-secret-scan-precommit", {
  repo_path: "apps/new-app",
  scan_history: true
})
```

## Cross-references

- **Source regex:** `~/.claude/scripts/phase3/check-secrets.sh`, `pre-rsync-achilles-grep.sh`
- **Related skill:** `~/.claude/skills/setup-pre-commit/` (general pre-commit-framework setup; this layer adds Mundi-specific rules)
- **Companion:** `tob-fp-check` + `mundi-qmd-fp-check-install` (false-positive handling when gitleaks flags a non-secret)
- **Memory:** `feedback_no_parallel_scraping.md`, past leak incident context
- **KB:** `docs/knowledge-base/outputs/qmd-action-items-for-wave2.md` item #3

## Safety

- **Never bypass with `--no-verify` for real secrets.** Fix the file.
- **Don't commit `config/api_keys.json`.** `.gitignore` already handles it; don't override.
- **If pre-commit hook fails after install, investigate — never silence.**
- **History scan matters.** A clean pre-commit on a repo with already-leaked history gives false confidence.

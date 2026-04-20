---
name: mundi-qmd-auth-refresh-hub
description: Centralized proactive auth/session refresh across all Mundi auth-gated providers (PitchBook, CapIQ, Supabase, Unipile, Cognito/OKTA-SNL). Monitor token TTL, refresh before 401s, codify the shared headful-Chrome-under-Xvfb + cookie-dump + systemctl-restart + circuit-breaker-close pattern. Use when setting up new auth-gated scrapers, debugging 401 loops, or scheduling preventive refresh crons.
allowed-tools: Read, Write, Edit, Bash, Grep, Glob
---

# Mundi QMD — Auth Refresh Hub

## Overview

Runbook for the auth/session refresh pattern used across all Mundi auth-gated data providers. Addresses the recurring failure mode: 401 hits a scraper → circuit opens → agent retries → retries burn account → ban. The fix is **proactive refresh** before TTL expires, not reactive refresh after 401.

Current providers gated by this pattern:
- **PitchBook** — SSO + MFA + 12h session TTL, `apps/pitchbook-mcp/scripts/refresh-pb-cookies.sh`
- **CapIQ** — S&P Capital IQ SSO + MFA, `apps/capiq-mcp/scripts/refresh-capiq-cookies.sh`
- **Supabase** — service-role JWT refresh (different pattern, but same hub)
- **Unipile** — API token with LinkedIn cookie pool
- **Cognito / OKTA-SNL** — OAuth flows for various partners

## When to use

- Setting up a new auth-gated scraper (PB, CapIQ-style)
- Debugging a "401 loop" where service keeps retrying and burns the account
- Scheduling preventive refresh cron (belt-and-braces before TTL expires)
- Onboarding a 2nd/3rd account for rotation (see `project_pb_account_rasvhki.md`)
- Recovering from a silent-ban (account appears healthy but all calls 401)

## Core pattern (the recipe)

```
preflight      → read cookie TTL from file; if < N hours left, refresh NOW
refresh        → Playwright headful under Xvfb + x11vnc (if MFA needed, operator attaches)
extract        → dump all cookies to file (PB: SESSION + pbCust + 5 others; CapIQ: session + MFA tokens)
verify         → make an authenticated API call to confirm cookies work BEFORE restarting service
restart        → sudo systemctl restart <service>; wait for active
close-circuit  → explicit API call to clear the "circuit open" state in pace_tracker.py
alert          → ClickUp webhook on any failure; Grafana annotation on success
```

## I/O contract (MWP)

**state_reads:**
- `~/Mundi Princeps/config/api_keys.json` — fallback creds if present
- `apps/pitchbook-mcp/config/pitchbook_cookies.json` — cookie file, check TTL
- `apps/capiq-mcp/config/capiq_cookies.json` — same
- `~/.claude/projects/-Users-mundiprinceps-Mundi-Princeps/memory/feedback_pb_no_reverification_loop.md` — keep-signed-in + trust-device rules
- `~/.claude/projects/.../memory/reference_server_side_sso_login.md` — Xvfb + x11vnc + real Chrome pattern

**state_writes:**
- Updated cookie files (atomic write + fsync)
- systemd journal entries (service restart)
- `~/.claude-mem/logs/auth-refresh-<provider>-<ts>.log` (optional audit)
- ClickUp alert on failure (via webhook per `apps/pitchbook-mcp/src/alerting.py`)

## Refresh protocols per provider

### PitchBook
Script: `apps/pitchbook-mcp/scripts/refresh-pb-cookies.sh`
- Auto mode: headless Playwright with saved cookies (if SSO still valid)
- `--vnc` mode: spawns Xvfb + x11vnc :1, operator attaches, completes MFA manually
- Success signal: all 13 cookies present, SESSION token updated, `pbCust` present
- **Critical:** preserve the Achilles Chrome profile — wiping it = re-do MFA every 12h

### CapIQ
Script: `apps/capiq-mcp/scripts/refresh-capiq-cookies.sh`
- Triggers MFA; operator drops MFA code into a tmux pane as the script waits
- Uses Scrapling (not Playwright) to bypass Akamai bot detection on the refresh call itself
- Circuit breaker in `apps/capiq-mcp/src/pace_tracker.py` — explicit close after refresh

### Supabase
Different pattern — service-role JWT doesn't expire, but user-role JWTs do. Refresh via:
```bash
curl -X POST "https://<project>.supabase.co/auth/v1/token?grant_type=refresh_token" \
  -H "apikey: <anon>" -d '{"refresh_token": "<r>"}'
```

### Unipile
LinkedIn cookie pool — rotate accounts, verify each via `GET /me`. Token in `config/api_keys.json`.

## Preventive schedule

Cron entries per provider (on Achilles):
```cron
# PB: refresh every 8h (well before 12h TTL)
0 */8 * * * bash /home/mundi/Mundi\ Princeps/apps/pitchbook-mcp/scripts/refresh-pb-cookies.sh auto
# CapIQ: every 6h (TTL varies)
30 */6 * * * bash /home/mundi/Mundi\ Princeps/apps/capiq-mcp/scripts/refresh-capiq-cookies.sh auto
```

## Failure modes

| failure | recovery |
|---|---|
| MFA required + no operator | alert ClickUp; switch to `--vnc` mode; wait for attach |
| Playwright can't reach site (Cloudflare block) | fall back to Xvfb + real Chrome profile |
| Cookies refreshed but 401 persists | account may be banned — check homepage as user, NOT as API (see `project_pb_account2_banned.md`) |
| Circuit breaker stays open after refresh | explicit reset via service admin endpoint |
| Cookie file corrupted | restore from `config/pitchbook_cookies.json.bak` (keep 3 rolling) |

## Safety rules

- **Never** refresh cookies in a retry loop after a 401. One attempt, then halt + alert.
- **Never** parallelize refresh across accounts (see `feedback_no_parallel_scraping.md`).
- **Verify BEFORE restart** — restart after verify means service never hits with bad cookies.
- Memory `project_pb_account_banned.md` + `project_pb_account2_banned.md` — two accounts already lost to retry loops. Third strike = manual only.

## Cross-references

- **Implementations to read:**
  - `apps/pitchbook-mcp/scripts/refresh-pb-cookies.sh`
  - `apps/capiq-mcp/scripts/refresh-capiq-cookies.sh`
  - `apps/pitchbook-mcp/src/alerting.py` — alert_cookie_stale + alert_cookie_expired
  - `apps/pitchbook-mcp/src/client/__init__.py` — `is_circuit_open` check
  - `apps/capiq-mcp/src/pace_tracker.py` — circuit breaker
- **Memory:** `feedback_pb_no_reverification_loop.md`, `reference_server_side_sso_login.md`, `project_pb_account_banned.md`, `project_pb_account_rasvhki.md`
- **KB:** `docs/knowledge-base/outputs/qmd-action-items-for-wave2.md` item #2
- **Related skills:** `saraev-cc-sync-thing-two-machine`, `saraev-infra-modal-authentication-token-management`

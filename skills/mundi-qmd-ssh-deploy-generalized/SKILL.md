---
name: mundi-qmd-ssh-deploy-generalized
description: Provider-aware SSH deploy skill — 7-step template (verify-dir → git-ff-pull → pip-install → systemctl-restart → wait-active → tool-count-sanity → CLI-entrypoint-check) generalized across PB, CapIQ, KadenVerify, investor-outbound, signal-pipeline. Use when deploying code to Achilles / mundi-ralph, setting up deploy for a new app, or debugging a stalled deploy.
allowed-tools: Read, Write, Edit, Bash, Grep, Glob
---

# Mundi QMD — SSH Deploy Generalized

## Overview

The canonical 7-step deploy pattern. Addresses: every Mundi app-to-server deploy follows the same shape, but each app has its own slightly-different script. Generalizing prevents drift + makes onboarding new apps trivial.

Reference implementation: `apps/pitchbook-mcp/scripts/deploy-pb-counterparty-achilles.sh` (152 lines).

## When to use

- Deploying a code change to Achilles (mundi-ralph 149.28.37.34) or developer-db (108.61.158.220)
- Setting up deploy for a new MCP / app / service
- Debugging "deploy started but service didn't come back up"
- Post-mortem on a failed deploy
- Onboarding a new team member to the deploy protocol

## The 7-step protocol

```
[1] Verify working directory
    cd to app dir; check git status clean; confirm branch + HEAD

[2] Git fast-forward pull
    git fetch origin <branch>; git merge --ff-only origin/<branch>
    FAIL if not FF-only — surface conflict, don't force

[3] Install / update dependencies
    if Python app: python -m pip install -e . (inside venv)
    if Node app: pnpm install --frozen-lockfile
    FAIL if install fails — don't restart service

[4] Systemctl restart
    sudo systemctl restart <service-name>
    (service name convention: <app>-mcp, kadenverify, signal-pipeline, etc.)

[5] Wait for active
    for i in {1..20}; do
      systemctl is-active <service> && break
      sleep 1
    done
    FAIL after 20s — don't proceed with smoke test

[6] Service-specific health check
    PB:     tool-count sanity: expect 224 pb_tool decorators
    CapIQ:  tool-count sanity: expect 81 @capiq_tool / @mcp.tool
    Generic HTTP service: curl /healthz; expect 200

[7] CLI entrypoint verification (if applicable)
    source venv && <entry-point> --help
    FAIL if help text missing expected flags (means bad install)
```

## I/O contract (MWP)

**state_reads:**
- `apps/<app>/deploy-config.yaml` OR per-app deploy script
- `~/Mundi Princeps/CLAUDE.md` — servers table (mundi-ralph 149.28.37.34, developer-db 108.61.158.220)
- `apps/<app>/pyproject.toml` or `package.json` — dep manifest

**state_writes:**
- `apps/<app>/deploy-log/<date>.log` — deploy record (git SHA, dep changes, health check results)
- systemd journal entries (service lifecycle)

## Canonical template

```bash
#!/usr/bin/env bash
# Generated from mundi-qmd-ssh-deploy-generalized
set -euo pipefail

APP="${1:?Usage: deploy <app> <server>}"
SERVER="${2:?Usage: deploy <app> <server>}"
BRANCH="${BRANCH:-main}"

# Map app → service + health check
declare -A SERVICE_MAP=(
  ["pitchbook-mcp"]="pitchbook-mcp"
  ["capiq-mcp"]="capiq-mcp"
  ["kadenverify"]="kadenverify"
  ["signal-pipeline"]="signal-pipeline"
  ["investor-outbound-mcp"]="investor-outbound-mcp"
)
declare -A TOOL_COUNT_EXPECTED=(
  ["pitchbook-mcp"]="224"
  ["capiq-mcp"]="81"
)
declare -A PORT_MAP=(
  ["pitchbook-mcp"]="8766"
  ["capiq-mcp"]="8768"
  ["investor-outbound-mcp"]="8770"
)

SERVICE="${SERVICE_MAP[$APP]}"

ssh $SERVER <<EOF
  set -euo pipefail

  # [1] Verify working dir
  cd "/home/mundi/Mundi Princeps/apps/$APP" || exit 1
  git status --short || exit 1

  # [2] FF pull
  git fetch origin $BRANCH
  git merge --ff-only origin/$BRANCH

  # [3] Install deps
  if [ -f pyproject.toml ]; then
    source .venv/bin/activate
    python -m pip install -e . --quiet
  elif [ -f package.json ]; then
    pnpm install --frozen-lockfile
  fi

  # [4] Restart
  sudo systemctl restart $SERVICE

  # [5] Wait active
  for i in {1..20}; do
    systemctl is-active $SERVICE && break
    sleep 1
  done
  systemctl is-active $SERVICE || { echo "service did not start"; exit 1; }

  # [6] Tool-count / health check
  if [ -n "${TOOL_COUNT_EXPECTED[$APP]:-}" ]; then
    COUNT=\$(grep -rhE "@(pb_tool|capiq_tool|mcp\.tool)" src/ | wc -l)
    [ "\$COUNT" -ge "${TOOL_COUNT_EXPECTED[$APP]}" ] || { echo "tool count low: \$COUNT"; exit 1; }
  fi
  if [ -n "${PORT_MAP[$APP]:-}" ]; then
    ss -ltn | grep -q ":${PORT_MAP[$APP]}" || { echo "port not listening"; exit 1; }
  fi

  # [7] CLI entrypoint check (per-app)
  # (customize per app)

  echo "OK: $APP deploy complete"
EOF
```

## Per-app ports + tool counts

| app | service | port | tool count | health check |
|---|---|---|---|---|
| pitchbook-mcp | pitchbook-mcp | 8766 | 224 | ss + pytest --collect |
| capiq-mcp | capiq-mcp | 8768 | 81 | ss + pytest --collect |
| investor-outbound-mcp | investor-outbound-mcp | 8770 | N/A | ss + curl /healthz |
| kadenverify | kadenverify | 8080 | N/A | curl /healthz + queue depth |
| signal-pipeline | signal-pipeline | N/A | N/A | cron healthy + last run OK |

## Failure modes

| failure | recovery |
|---|---|
| Step 2 FF fails (branch diverged) | abort; investigate divergence on server manually; NEVER force-push |
| Step 3 pip install fails | abort; don't restart; fix dep issue first |
| Step 5 service didn't start | `journalctl -u <service> -n 50` — surface log; don't auto-retry |
| Step 6 tool count low | investigate — may be intentional (refactor) or regression |
| Port not listening | service started but crashed; log check mandatory |

## Invocation

```bash
bash ~/.claude/skills/mundi-qmd-ssh-deploy-generalized/scripts/deploy.sh \
  pitchbook-mcp achilles-mundi
```

## Cross-references

- **Canonical template to read:** `apps/pitchbook-mcp/scripts/deploy-pb-counterparty-achilles.sh`
- **Additional refs:** `apps/capiq-mcp/` deploy workflow (git pull + sudo systemctl restart), `apps/pitchbook-mcp/CLAUDE.md` §Deployment
- **Server facts:** `~/Mundi Princeps/CLAUDE.md` — mundi-ralph (149.28.37.34), developer-db (108.61.158.220)
- **Memory:** `project_capiq_mcp.md`, `project_pb_deployed.md`
- **KB:** `docs/knowledge-base/outputs/qmd-action-items-for-wave2.md` item #6, `docs/knowledge-base/outputs/achilles-migration-2026-04-18.md`
- **Related skills:** `mundi-qmd-auth-refresh-hub` (post-deploy cookie-refresh if service also reset)

## Safety

- **FF-only pulls.** Never `git pull` without `--ff-only` — prevents accidental merge commits on production branch.
- **Check is-active BEFORE smoke test.** Waiting 30s then failing is better than running smoke test on dead service.
- **Don't skip health check.** "Service is active" ≠ "service is healthy."
- **Log everything.** Deploy log at `apps/<app>/deploy-log/<date>.log` — enables post-mortem.

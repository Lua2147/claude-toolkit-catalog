---
name: site-health
description: Check production site availability. Use during heartbeats or when asked about site status.
---

# Site Health Check

Quick HTTP health checks for your production sites.

## Usage

```bash
{baseDir}/scripts/check.sh
```

## Setup

Edit `scripts/check.sh` to add your sites:

```bash
SITES=(
  "https://yoursite.com|Your Site|expected text"
  "https://app.yoursite.com|Your App|expected text"
)
```

Each entry: `URL|Display Name|Text to expect in response` (optional text check).

## How It Works

1. Sends a GET request to each URL
2. Checks for HTTP 200 (follows redirects)
3. Optionally verifies response contains expected text
4. Reports pass/fail for each site
5. Returns non-zero exit code if any site is down

## Integration with Heartbeats

Add to your HEARTBEAT.md:

```markdown
## Site Health Check (every heartbeat)
1. Run `~/clawd/skills/site-health/scripts/check.sh`
2. If ANY failures: alert immediately
```

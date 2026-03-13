---
name: revenue-metrics
description: Pull deal pipeline and revenue metrics from Supabase CRM. Use when checking pipeline health, running daily reviews, comparing periods, or answering deal performance questions.
---

# Revenue & Pipeline Metrics

Track deal pipeline, opportunity values, and business metrics from the Kadenwood CRM.

## Quick Metrics via Supabase MCP

Use the `supabase` MCP server to run these queries against the Kadenwood project (peqbuukrhbdvdqrmknhz):

### Pipeline Overview
```sql
SELECT
  stage,
  COUNT(*) as deals,
  SUM(estimated_value) as total_value,
  AVG(estimated_value) as avg_deal_size
FROM opportunities
WHERE status = 'active'
GROUP BY stage
ORDER BY stage;
```

### This Week vs Last Week
```sql
-- Won this week
SELECT COUNT(*) as won, SUM(estimated_value) as value
FROM opportunities
WHERE status = 'won' AND updated_at >= DATE_TRUNC('week', CURRENT_DATE);

-- Won last week
SELECT COUNT(*) as won, SUM(estimated_value) as value
FROM opportunities
WHERE status = 'won'
AND updated_at >= DATE_TRUNC('week', CURRENT_DATE) - INTERVAL '7 days'
AND updated_at < DATE_TRUNC('week', CURRENT_DATE);
```

### Activity Volume
```sql
SELECT
  DATE(created_at) as day,
  COUNT(*) as activities,
  COUNT(DISTINCT user_id) as active_users
FROM activities
WHERE created_at >= CURRENT_DATE - INTERVAL '7 days'
GROUP BY DATE(created_at)
ORDER BY day DESC;
```

### Stale Pipeline (no activity in 7+ days)
```sql
SELECT o.name, o.stage, o.estimated_value,
  MAX(a.created_at) as last_activity,
  CURRENT_DATE - MAX(a.created_at)::date as days_stale
FROM opportunities o
LEFT JOIN activities a ON a.opportunity_id = o.id
WHERE o.status = 'active'
GROUP BY o.id, o.name, o.stage, o.estimated_value
HAVING MAX(a.created_at) < CURRENT_DATE - INTERVAL '7 days'
  OR MAX(a.created_at) IS NULL
ORDER BY days_stale DESC;
```

### KPI Snapshot
```bash
cd ~/Mundi\ Princeps/apps/kadenwood && node scripts/kpi-audit.js 2>/dev/null
```

## Stripe (future — when payment processing is live)

The original `scripts/stripe-metrics.py` is preserved for when Kadenwood processes payments via Stripe. Configure by:
1. Storing Stripe key at `~/.config/stripe/api_key`
2. Editing the `ACCOUNTS` dict in the script

## Key Metrics to Track

| Metric | Query | Frequency |
|--------|-------|-----------|
| Active pipeline value | SUM(estimated_value) WHERE active | Daily |
| Deals won this week | COUNT WHERE won AND this week | Daily |
| Pipeline velocity | AVG days per stage transition | Weekly |
| Stale deals (7+ days) | No activity in 7 days | Daily |
| Task completion rate | Completed / total due | Daily |
| Outbound response rate | Responses / messages sent | Weekly |

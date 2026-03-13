---
name: daily-review
description: Run a daily deal pipeline review and plan the next day. Use at the end of each day to summarize deal activity, pipeline health, KPI snapshot, and propose tomorrow's priorities.
---

# Daily Review — Pipeline Deep Dive

Run this at the end of each day to close out the day and set up tomorrow.

## Process

### 1. Pipeline Snapshot

Query Supabase for current pipeline state:

```sql
-- Opportunities by stage
SELECT stage, COUNT(*) as count, SUM(estimated_value) as total_value
FROM opportunities WHERE status = 'active'
GROUP BY stage ORDER BY stage;

-- Deals closed this week
SELECT * FROM opportunities
WHERE status = 'won' AND updated_at > NOW() - INTERVAL '7 days';

-- Stale opportunities (no activity in 7+ days)
SELECT o.name, o.stage, o.estimated_value, MAX(a.created_at) as last_activity
FROM opportunities o
LEFT JOIN activities a ON a.opportunity_id = o.id
WHERE o.status = 'active'
GROUP BY o.id, o.name, o.stage, o.estimated_value
HAVING MAX(a.created_at) < NOW() - INTERVAL '7 days' OR MAX(a.created_at) IS NULL;

-- Tasks due today/overdue
SELECT * FROM tasks WHERE status != 'completed'
AND due_date <= CURRENT_DATE ORDER BY due_date;
```

Use the Supabase MCP server to run these queries.

### 2. KPI Health Check

```bash
# Run KPI quality audit
cd ~/Mundi\ Princeps/apps/kadenwood && node scripts/kpi-audit.js
```

Key metrics to track:
- **Active opportunities** — total count and value
- **Pipeline velocity** — avg days per stage
- **Conversion rate** — opportunities won / total
- **Overdue tasks** — count and owners
- **Stale deals** — no activity in 7+ days

### 3. Outbound Activity

```sql
-- LinkedIn outbound stats (if HeyReach campaigns active)
-- Check via HeyReach MCP: get_overall_stats

-- Email campaign performance
-- Check via Instantly API or Supabase auto_responder project
```

### 4. Day Review
- What got done from today's plan?
- What didn't get done and why?
- What deals moved forward? Which stalled?

### 5. Propose Tomorrow's Plan
- 3-5 concrete actions ranked by expected deal impact
- Include both execution tasks and outreach priorities
- Flag any deals that need founder attention

### 6. Send Summary

## Report Template

```markdown
## Daily Review — YYYY-MM-DD

### Pipeline
| Stage | Count | Total Value |
|-------|-------|-------------|
| ... | ... | ... |
| **Total Active** | **N** | **$X** |

### Activity
- New opportunities: N
- Deals advanced: N
- Tasks completed: N / N due
- Overdue tasks: N

### Outbound
- LinkedIn messages sent: N
- Email campaigns active: N
- Responses received: N

### Execution
- ✅ Completed: [items]
- ❌ Missed: [items + why]
- 🔄 Carried: [items moving to tomorrow]

### Tomorrow's Plan
1. [Highest impact action]
2. [Second priority]
3. [Third priority]

### Attention Required
[Deals/issues that need founder input]
```

## Infrastructure

- **Supabase project**: peqbuukrhbdvdqrmknhz (Kadenwood CRM)
- **CRM dashboard**: war.kadenwoodgroup.com
- **KPI system**: 294 KPIs across 20+ categories
- **HeyReach**: LinkedIn outbound campaigns
- **Instantly**: Cold email platform

---
name: escalation
description: "Use when structuring support escalations for engineering, product, or leadership with full context, reproduction steps, and business impact. Also use when assessing whether an issue warrants escalation or when writing an escalation brief."
---

# Escalation Skill

You are an expert at determining when and how to escalate support issues. You structure escalation briefs that give receiving teams everything they need to act quickly.

## When to Escalate vs. Handle in Support

### Handle in Support When:
- The issue has a documented solution or known workaround
- It's a configuration or setup issue you can resolve
- The customer needs guidance or training, not a fix

### Escalate When:
- **Technical**: Bug confirmed and needs a code fix, infrastructure investigation needed, data corruption or loss
- **Complexity**: Issue beyond support's ability to diagnose, requires access support doesn't have
- **Impact**: Multiple customers affected, production system down, data integrity at risk, security concern
- **Business**: High-value customer at risk, SLA breach imminent or occurred
- **Time**: Issue open beyond SLA, normal support channels aren't progressing
- **Pattern**: Same issue reported by 3+ customers, recurring issue supposedly fixed

## Escalation Tiers

| From → To | When | What to Include |
|-----------|------|-----------------|
| L1 → L2 | Deeper investigation needed | Ticket summary, steps tried, customer context |
| L2 → Engineering | Confirmed bug, needs code change | Reproduction steps, environment, logs, business impact |
| L2 → Product | Feature gap, design decision needed | Use case, business impact, frequency, competitive pressure |
| Any → Security | Data exposure, unauthorized access, vulnerability | What was observed, who's affected, containment steps |
| Any → Leadership | High-revenue customer churn risk, SLA breach, PR/legal risk | Full business context, revenue at risk, specific decision needed |

## Structured Escalation Format

```
ESCALATION: [One-line summary]
Severity: [Critical / High / Medium]
Target: [Engineering / Product / Security / Leadership]

IMPACT
- Customers affected: [Number and names if relevant]
- Workflow impact: [What's broken for them]
- Revenue at risk: [If applicable]
- SLA status: [Within SLA / At risk / Breached]

ISSUE DESCRIPTION
[3-5 sentences: what's happening, when it started, scope of impact]

REPRODUCTION STEPS (for bugs)
1. [Step]
2. [Step]
Expected: [X]
Actual: [Y]
Environment: [Details]

WHAT'S BEEN TRIED
1. [Action] → [Result]
2. [Action] → [Result]

CUSTOMER COMMUNICATION
- Last update: [Date — what was said]
- Customer expectation: [What they expect and by when]

WHAT'S NEEDED
- [Specific ask: investigate, fix, decide, approve]
- Deadline: [Date/time]

SUPPORTING CONTEXT
- [Ticket links, internal threads, logs/screenshots]
```

## Severity Shorthand

- **Critical**: Production down, data at risk, security breach, multiple high-value customers affected. Immediate attention.
- **High**: Major functionality broken, key customer blocked, SLA at risk. Same-day attention.
- **Medium**: Significant issue with workaround, important but not urgent. This week.

## Follow-up Cadence

| Severity | Internal Follow-up | Customer Update |
|----------|-------------------|-----------------|
| Critical | Every 2 hours | Every 2-4 hours |
| High | Every 4 hours | Every 4-8 hours |
| Medium | Daily | Every 1-2 business days |

## Writing Reproduction Steps

1. Start from a clean state (account type, configuration, permissions)
2. Be specific: "Click the Export button in the top-right of the Dashboard page"
3. Include exact values: specific inputs, dates, IDs
4. Note the environment: browser, OS, account type, feature flags
5. Capture frequency: always reproducible? intermittent?
6. Include evidence: screenshots, error messages, logs
7. Note what you've ruled out

## De-escalation

De-escalate when:
- Root cause found and support-resolvable
- Workaround found that unblocks customer
- New information changes severity assessment

When de-escalating: notify the team, update ticket, inform customer, document learnings.

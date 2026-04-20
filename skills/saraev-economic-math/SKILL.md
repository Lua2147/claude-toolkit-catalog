---
name: saraev-economic-math
description: One-page quick-maths for agency / AI-automation economics — retainer pricing, margin targets, break-even per hire, token cost per lead, CAC vs LTV. Saraev's framing that most agency operators fail on the math, not the service. Use when pricing a retainer, evaluating a client's profitability, deciding whether to hire, or estimating token cost per outbound.
allowed-tools: Read, Bash
---

# Saraev — Economic Math (Quick-Maths)

## Overview

Saraev's pattern: most AI-automation / agency operators get the service right and the math wrong. They underprice, under-estimate token costs, confuse margin with revenue, and hire before the next role pays for itself. This skill codifies the quick-maths so the numbers don't sink the business.

Source: `uSTGNHGFOAo @ 1:52:30` (Saraev transcript, wave 1 catalog P098).

## When to use

- Pricing a new retainer (what do we need to charge to make N% margin?)
- Evaluating an existing client (are they still profitable after scope creep?)
- Deciding whether to hire (what's the break-even?)
- Estimating token cost per outbound / per enriched lead / per scraped signal
- Comparing service packages (monthly retainer vs outcome-based vs hybrid)

## Quick-maths formulas

### 1. Retainer pricing
```
target_margin_pct = 0.60          # 60% after delivery cost
delivery_hours    = 20/month      # delivery time estimate
loaded_hourly     = 150           # labor cost loaded
delivery_cost     = delivery_hours × loaded_hourly     # = $3,000
min_retainer      = delivery_cost / (1 - target_margin_pct)   # = $7,500
```

### 2. Margin sanity check
```
revenue         = retainer × clients
variable_cost   = (delivery + API) × clients
fixed_cost      = rent + tooling + salaries_fixed
margin          = (revenue - variable_cost - fixed_cost) / revenue

if margin < 0.40 → retainer too low OR delivery too expensive
```

### 3. Break-even per hire
```
new_hire_loaded = $120k/year      # salary + tax + benefits + laptop
revenue_per_hour = $200            # after delivery assumed utilization
required_billable_hours = 120_000 / 200   # = 600 hrs/year
                                    # = 12 hrs/week billable
# At 50% utilization, need ~24 hrs/week of capacity to sell
```

### 4. Token cost per lead
```
enrichment_prompt_tokens = 800
enrichment_response_tokens = 400
model = "claude-sonnet-4.6"       # $3/M in, $15/M out
cost_per_enrich = (800 × 3 + 400 × 15) / 1_000_000
                = $0.0084 per lead

# For 1000 leads/day: $8.40/day = $252/month
# If charging $X/lead, break-even at $X > cost_per_enrich * 1.4 (40% margin floor)
```

### 5. CAC vs LTV quick-check
```
cac    = (ad_spend + sdr_cost + tooling) / closed_deals
ltv    = avg_retainer × avg_months_retained × margin_pct
# Healthy: LTV / CAC > 3
# Unhealthy: < 2 means you're burning runway per acquisition
```

### 6. Token budget per outbound cycle
```
per_send = prompt_in (1.5k) + response_out (0.3k) = ~$0.008 on Sonnet
per_full_campaign = 5 touches × $0.008 = $0.04 per lead
at 10,000 leads/month = $400/month tokens
# Add 20% buffer for retries/regenerations = $480/month
```

## Common traps Saraev calls out

1. **Revenue ≠ margin.** "We did $50k last month" means nothing without cost data.
2. **Hire on trend, not spike.** One big month doesn't fund a $120k hire.
3. **Token cost estimated low.** People forget retries, re-generations, verification passes. Budget 2× your best-case estimate.
4. **Delivery time underestimated.** Initial scoping always assumes 50% less time than actual.
5. **Utilization assumed 80%+.** Real sustained utilization is 40-60%.
6. **Forgetting variable costs scale with clients.** API fees, seat licenses, enrichment credits — they grow with client count.

## Invocation

Interactive — ask the user their inputs, run the math:

```python
Skill(skill="saraev-economic-math", {
  scenario: "price_retainer" | "margin_check" | "hire_break_even" | "token_cost" | "cac_ltv",
  inputs: {...}
})
# Returns the calculation with a sensitivity table (e.g., "at 50% utilization: X; at 70%: Y")
```

Or standalone — paste into a markdown cell for a calculation scratchpad.

## Safety / limits

- These are **estimates**. Real business accounting uses actuals.
- Margin math is **pre-tax**. Add 25-35% for tax depending on entity structure.
- Token pricing changes monthly — always verify with current Anthropic/OpenAI/Gemini pricing before quoting.
- **Don't commit a retainer price from this skill alone** — run it past your P&L + accountant.

## Cross-references

- **Adjacent (not duplicates):** `saraev-biz-token-conservation-strategy` (tactical token saving), `pricing-strategy`, `ariz-pricing-strategy`, `saraev-biz-value-proposition-framing` (charge what value-created justifies)
- **Memory:** `project_beancount_accounting.md` (Beancount setup for real P&L tracking)
- **KB:** `docs/knowledge-base/wiki/09-business-strategy/INDEX.md`
- **Source:** `docs/knowledge-base/outputs/saraev-skill-catalog-wave1.md:1963` — Saraev transcript `uSTGNHGFOAo @ 1:52:30`

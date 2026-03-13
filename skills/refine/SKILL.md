---
name: refine
description: Use when an output needs polishing before shipping — runs a convergence loop of self-scoring, diagnosis, and rewriting until quality threshold is met
---

# Refine: Convergence Loop

## Purpose

Take any draft output (doc, email, code, deck content, strategy) and iteratively improve it by scoring against explicit criteria, diagnosing weaknesses, and rewriting until quality converges.

## Process

### Step 1: Identify the Output and Criteria

Ask the user (or infer from context):
- **What is being refined?** (paste or reference the draft)
- **What are the quality criteria?** (use defaults below if not specified)

**Default criteria by output type:**

| Type | Criteria (score 1-10 each) |
|------|---------------------------|
| Writing/content | Clarity, specificity, conciseness, actionability |
| Code | Correctness, readability, edge case handling, performance |
| Email/outreach | Tone, brevity, clarity of ask, personalization |
| Strategy/analysis | Reasoning depth, practical applicability, evidence quality, structure |
| Investor materials | Accuracy, professionalism, persuasiveness, completeness |

### Step 2: Score Version 1

Rate the draft against each criterion (1-10). Be honest and specific — vague scores are useless.

For any criterion below 8: write a **one-sentence diagnosis** identifying the specific weakness. Not "could be better" — identify exactly what's wrong and where.

Calculate overall score (average).

### Step 3: Rewrite

Apply fixes for every criterion below 8. Produce the next version.

### Step 4: Re-score and Convergence Check

Score the new version against the same criteria. Then:

- **All criteria >= 8?** Stop. Present final version.
- **Overall score improved by < 0.5 from previous version?** Stop. Diminishing returns.
- **3 iterations completed?** Stop. Present best version with remaining weaknesses noted.
- **Otherwise:** Repeat steps 3-4.

### Step 5: Final Output

Present:
```
Refined Output
══════════════
[the final version]

Scores: [criterion]: [score] | [criterion]: [score] | ...
Overall: [X]/10

Changelog (v1 → final):
• [what changed and why, 1 line per change]

Iterations: [N] | Converged: [yes/no]
```

## Rules

- Maximum 3 iterations. If it's not converging by then, the problem is the source material, not the polish.
- Never inflate scores. A 9 means genuinely excellent, not "I rewrote it so it must be better."
- If v1 already scores 8+ on everything, say so and don't waste iterations.
- Keep the changelog specific: "Replaced generic claim in paragraph 2 with revenue data" not "improved specificity."
- Do NOT add length during refinement. Conciseness is a criterion, not a casualty.

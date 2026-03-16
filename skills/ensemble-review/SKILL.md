---
name: ensemble-review
description: Multi-instance review patterns — run the same prompt N times, aggregate via majority vote or union of findings. For compliance, code review, and document QC. Maps to CCA Domain 4.
---

# Ensemble Review

## Overview

Run the same review task across multiple Claude instances and aggregate results. This catches findings that a single pass misses (due to attention variability) and builds confidence through consensus. Particularly valuable for high-stakes reviews where false negatives are costly.

## Core Pattern: N-Instance Review

```python
import asyncio
from anthropic import AsyncAnthropic

client = AsyncAnthropic()
N_INSTANCES = 3

async def single_review(document: str, instance_id: int) -> dict:
    """Run one review instance with temperature > 0 for diversity."""
    response = await client.messages.create(
        model="claude-sonnet-4-20250514",
        max_tokens=2048,
        temperature=0.3,  # Slight randomness for diverse findings
        tools=[review_findings_tool],
        tool_choice={"type": "tool", "name": "submit_findings"},
        messages=[{
            "role": "user",
            "content": f"Review this document for compliance issues:\n\n{document}"
        }]
    )
    findings = response.content[0].input["findings"]
    return {"instance": instance_id, "findings": findings}

async def ensemble_review(document: str) -> list:
    """Run N parallel reviews and aggregate."""
    tasks = [single_review(document, i) for i in range(N_INSTANCES)]
    results = await asyncio.gather(*tasks)
    return aggregate_findings(results)
```

## Aggregation Strategies

### Majority Vote (for classification)

Use when the task has a discrete answer (pass/fail, category A/B/C).

```python
def majority_vote(results: list[dict]) -> str:
    """Return the classification chosen by >50% of instances."""
    from collections import Counter
    votes = [r["classification"] for r in results]
    winner, count = Counter(votes).most_common(1)[0]
    confidence = count / len(votes)
    return {"classification": winner, "confidence": confidence, "votes": votes}
```

### Union of Findings (for review/audit)

Use when each instance may catch different issues. Take the union, then deduplicate.

```python
def union_findings(results: list[dict]) -> list:
    """Merge findings from all instances, deduplicate by similarity."""
    all_findings = []
    for r in results:
        for finding in r["findings"]:
            # Check if a similar finding already exists
            if not any(is_duplicate(finding, existing) for existing in all_findings):
                finding["found_by"] = [r["instance"]]
                all_findings.append(finding)
            else:
                # Mark as confirmed by additional instance
                match = next(f for f in all_findings if is_duplicate(finding, f))
                match["found_by"].append(r["instance"])

    # Sort by confirmation count (findings seen by multiple instances rank higher)
    all_findings.sort(key=lambda f: len(f["found_by"]), reverse=True)
    return all_findings

def is_duplicate(a: dict, b: dict) -> bool:
    """Two findings are duplicates if they reference the same location and issue type."""
    return (a.get("location") == b.get("location") and
            a.get("issue_type") == b.get("issue_type"))
```

### Intersection (for high-precision filtering)

Use when false positives are costly. Only keep findings confirmed by all instances.

```python
def intersection_findings(results: list[dict], min_agreement: int = None) -> list:
    """Keep only findings confirmed by at least min_agreement instances."""
    if min_agreement is None:
        min_agreement = len(results)  # Require unanimity

    merged = union_findings(results)
    return [f for f in merged if len(f["found_by"]) >= min_agreement]
```

## Use Cases

### Code Review Ensemble

```python
CODE_REVIEW_PROMPT = """Review this code diff for:
1. Bugs and logic errors
2. Security vulnerabilities
3. Performance issues
4. Missing error handling

For each finding, provide:
- severity: critical / high / medium / low
- location: file and line reference
- issue: what is wrong
- fix: suggested correction
"""
# Run 3 instances, union findings, rank by confirmation count
```

### Compliance Document Review

```python
COMPLIANCE_PROMPT = """Review this contract clause against these regulatory requirements:
{requirements}

Flag any clause that:
- Contradicts a requirement
- Is ambiguous about a requirement
- Is missing a required provision

For each flag, cite the specific requirement it violates.
"""
# Run 5 instances for high-stakes compliance, intersection with min_agreement=3
```

### Data Quality Check

```python
QC_PROMPT = """Verify these extracted data fields against the source document.
For each field, confirm if the extraction is:
- correct: value matches source
- incorrect: value does not match source (provide correct value)
- unverifiable: source does not contain this information
"""
# Run 3 instances, majority vote per field
```

## Cost Management

| Instances | Cost Multiplier | Use When |
|-----------|----------------|----------|
| 2 | 2x | Quick sanity check |
| 3 | 3x | Standard review (good balance) |
| 5 | 5x | High-stakes compliance/legal |

Combine with Message Batches API for 50% discount on bulk ensemble reviews.

## When to Use

- Any review where a single miss has high cost (compliance, security, legal)
- Classification tasks where you need a confidence score
- Data extraction QC where accuracy must exceed 99%
- When a single Claude pass has shown inconsistent results on similar inputs

## Common Mistakes

1. **Temperature = 0 for all instances**: Identical temperature produces near-identical outputs, defeating the purpose
2. **No deduplication**: Union without dedup inflates finding counts with redundant issues
3. **Too many instances**: Beyond 5, diminishing returns. Cost grows linearly, finding discovery does not
4. **Ignoring disagreement signal**: When instances disagree strongly, that itself is information — flag for human review
5. **No structured output**: Free-text findings are hard to deduplicate — use `tool_choice` to force structured format

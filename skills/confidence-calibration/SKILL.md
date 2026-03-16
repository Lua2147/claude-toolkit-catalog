---
name: confidence-calibration
description: Asking Claude to self-rate confidence (1-5), routing based on score, calibration prompts, and human-in-the-loop escalation patterns. Maps to CCA Domain 4/5.
---

# Confidence Calibration

## Overview

Techniques for getting Claude to self-assess confidence on its outputs and using that signal to route decisions: auto-approve high-confidence answers, flag medium-confidence for review, and escalate low-confidence to humans. Critical for production systems where blind trust in model outputs creates risk.

## The Confidence Scale

```python
CONFIDENCE_PROMPT = """After answering, rate your confidence on this scale:

5 - Certain: The answer is directly supported by the provided context with no ambiguity
4 - High: Strong evidence supports the answer, minor interpretation needed
3 - Moderate: Some evidence supports the answer, but key details are missing or ambiguous
2 - Low: Limited evidence, significant assumptions required
1 - Very Low: Mostly guessing, insufficient information to answer reliably

Provide your answer, then state: CONFIDENCE: [1-5] with a one-line justification.
"""
```

## Routing Based on Confidence

### The Decision Matrix

```python
def route_by_confidence(answer: str, confidence: int, context: dict) -> str:
    """Route answer based on confidence score."""
    if confidence >= 4:
        return "auto_approve"      # Use answer directly
    elif confidence == 3:
        return "flag_for_review"   # Queue for human spot-check
    else:  # confidence <= 2
        return "escalate"          # Block until human reviews

# Implementation
result = extract_answer_and_confidence(response)

if route_by_confidence(result.answer, result.confidence, ctx) == "auto_approve":
    save_answer(result.answer)
elif route_by_confidence(result.answer, result.confidence, ctx) == "flag_for_review":
    save_answer(result.answer, status="pending_review")
    notify_reviewer(result)
else:
    create_human_task(result, priority="high")
```

### Extracting Confidence Programmatically

```python
import re

def extract_confidence(response_text: str) -> tuple[str, int, str]:
    """Extract answer, confidence score, and justification."""
    # Match "CONFIDENCE: N" pattern
    match = re.search(r'CONFIDENCE:\s*(\d)\s*[-—]?\s*(.*?)$', response_text, re.MULTILINE)
    if match:
        score = int(match.group(1))
        justification = match.group(2).strip()
        # Answer is everything before the confidence line
        answer = response_text[:match.start()].strip()
        return answer, score, justification

    # Fallback: no confidence found, treat as low
    return response_text, 1, "No confidence rating provided"
```

### Using Tool-Based Extraction (more reliable)

```python
confidence_tool = {
    "name": "submit_answer",
    "description": "Submit your answer with a confidence rating.",
    "input_schema": {
        "type": "object",
        "properties": {
            "answer": {"type": "string"},
            "confidence": {
                "type": "integer",
                "minimum": 1,
                "maximum": 5,
                "description": "1=very low, 2=low, 3=moderate, 4=high, 5=certain"
            },
            "confidence_justification": {
                "type": "string",
                "description": "One sentence explaining why you chose this confidence level"
            },
            "missing_information": {
                "type": "array",
                "items": {"type": "string"},
                "description": "What information would increase your confidence?"
            }
        },
        "required": ["answer", "confidence", "confidence_justification"]
    }
}
```

## Calibration Prompts

### Anchoring with Examples

Claude's confidence is better calibrated when you provide examples of what each level means in your domain:

```python
CALIBRATED_PROMPT = """Rate your confidence using these domain-specific anchors:

5 - The contract explicitly states this term (you can quote it)
4 - The term is strongly implied by multiple clauses taken together
3 - One clause suggests this, but other clauses could contradict it
2 - You are inferring from general legal patterns, not this specific contract
1 - The contract does not address this topic

Do NOT default to 3. A 3 means you found partial evidence. If you found no evidence, use 1.
"""
```

### Preventing Confidence Inflation

Claude tends to over-report confidence. Counter this with:

```
- "If you would change your answer given one additional paragraph of context, your confidence is at most 3."
- "If your answer relies on any assumption not stated in the document, reduce confidence by 1."
- "List what you do NOT know before rating confidence."
```

## Multi-Stage Confidence

For complex tasks, collect confidence at each stage:

```python
stages = [
    {"name": "extraction", "prompt": "Extract the key terms..."},
    {"name": "analysis", "prompt": "Analyze the extracted terms..."},
    {"name": "recommendation", "prompt": "Based on analysis, recommend..."},
]

# Overall confidence = minimum of stage confidences
# If extraction is low-confidence, analysis and recommendation are unreliable
overall_confidence = min(stage_results[s]["confidence"] for s in stages)
```

## When to Use

- Any production system where Claude's output drives business decisions
- Document review pipelines with varying document quality
- Data extraction where source documents are inconsistent
- Customer-facing Q&A systems where wrong answers have real consequences
- Regulatory or compliance workflows requiring audit trails

## Common Mistakes

1. **Not calibrating to domain**: Generic 1-5 scales produce inflated scores. Anchor to domain-specific examples
2. **Treating confidence as accuracy**: Confidence is Claude's self-assessment, not ground truth. Validate calibration empirically
3. **Binary routing (trust/don't trust)**: Three tiers (auto/review/escalate) is the minimum for useful routing
4. **Ignoring `missing_information`**: When Claude says what it needs, that is actionable — fetch the missing data and re-run
5. **No calibration monitoring**: Track confidence vs actual accuracy over time. If 90% of "confidence 4" answers are wrong, recalibrate thresholds
6. **Defaulting low-confidence to rejection**: Low confidence with `missing_information` is a retrieval signal, not a stop signal

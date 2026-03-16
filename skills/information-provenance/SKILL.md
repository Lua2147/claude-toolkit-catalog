---
name: information-provenance
description: Structured claim-source mappings, escalation trigger taxonomy, and codebase exploration protocols for traceable information handling. Maps to CCA Domain 5.
---

# Information Provenance

## Overview

Patterns for tracking where Claude's claims come from, distinguishing reliable from unreliable information sources, and systematically exploring codebases to build accurate mental models. Essential for any workflow where traceability and accuracy are non-negotiable.

## Structured Claim-Source Mappings

### The Provenance Record

Every factual claim should be traceable to a source:

```python
provenance_tool = {
    "name": "submit_analysis",
    "description": "Submit analysis with source provenance for each claim.",
    "input_schema": {
        "type": "object",
        "properties": {
            "claims": {
                "type": "array",
                "items": {
                    "type": "object",
                    "properties": {
                        "claim": {"type": "string", "description": "The factual assertion"},
                        "source": {"type": "string", "enum": [
                            "provided_document",   # From user-supplied text
                            "codebase",            # From reading project files
                            "web_search",          # From web search results
                            "training_knowledge",  # From Claude's training data
                            "inference"            # Derived from other claims
                        ]},
                        "source_reference": {"type": "string", "description": "File path, URL, or document section"},
                        "confidence": {"type": "integer", "minimum": 1, "maximum": 5},
                        "retrieval_date": {"type": "string", "description": "ISO 8601 date when source was accessed"}
                    },
                    "required": ["claim", "source", "confidence"]
                }
            },
            "summary": {"type": "string"}
        },
        "required": ["claims", "summary"]
    }
}
```

### Source Reliability Hierarchy

| Source | Reliability | Notes |
|--------|------------|-------|
| `provided_document` | Highest | User supplied, assumed ground truth |
| `codebase` | High | Read directly from files, verifiable |
| `web_search` | Medium | Current but may be inaccurate |
| `training_knowledge` | Low-Medium | May be outdated (cutoff: May 2025) |
| `inference` | Variable | Only as strong as the claims it builds on |

### Prompting for Provenance

```markdown
For each factual statement in your response, mark the source:

[DOC] — from the provided documents (cite section)
[CODE] — from reading project files (cite file path)
[SEARCH] — from web search results (cite URL)
[TRAINING] — from your training data (flag as potentially outdated)
[INFERRED] — derived from other facts (state which facts)

Example:
"The company's ARR is $12M [DOC: Q3 earnings transcript, page 4] and growing at
approximately 35% YoY [INFERRED: from Q2 ARR of $8.9M in same transcript]."
```

## Escalation Trigger Taxonomy

### Reliable Triggers (auto-proceed)

- Source is a provided document with clear, unambiguous statement
- Source is code that Claude just read from the project
- Claim is a direct quote with citation
- Multiple independent sources agree

### Unreliable Triggers (escalate to human)

- Source is training knowledge for any fact that could change (prices, team sizes, API behavior)
- Claim requires domain expertise Claude lacks (legal interpretation, medical diagnosis)
- Sources contradict each other
- Claim extrapolates beyond available data
- "I believe" or "typically" or "in most cases" — hedging language signals low provenance

### Trigger Implementation

```python
def should_escalate(claim: dict) -> bool:
    """Determine if a claim needs human verification."""
    # Always escalate training knowledge for mutable facts
    if claim["source"] == "training_knowledge" and claim.get("mutable", True):
        return True

    # Escalate low confidence regardless of source
    if claim["confidence"] <= 2:
        return True

    # Escalate inferences with low-confidence base claims
    if claim["source"] == "inference":
        base_claims = claim.get("based_on", [])
        if any(c["confidence"] <= 2 for c in base_claims):
            return True

    return False
```

## Codebase Exploration Protocol

A systematic approach to understanding an unfamiliar codebase before making claims about it.

### The Four-Step Protocol

```
Step 1: TREE — Get the directory structure
  $ find . -type f -name "*.ts" | head -50
  $ cat package.json  (or pyproject.toml, Cargo.toml)
  Goal: Understand project shape, language, framework

Step 2: ENTRY POINTS — Find where execution starts
  $ grep -r "app.listen\|createServer\|main()" --include="*.ts" -l
  $ grep -r "export default\|module.exports" --include="*.ts" -l | head -20
  Goal: Identify the application's entry points and exports

Step 3: KEY FILES — Read the most important files
  Read: package.json, tsconfig.json, CLAUDE.md, README.md
  Read: main entry point files identified in step 2
  Read: any config or schema files
  Goal: Understand dependencies, build system, conventions

Step 4: MENTAL MODEL — Form and validate understanding
  Write down: "This is a [framework] app that [purpose].
  It has [N] main modules: [list]. Data flows from [A] to [B] to [C]."
  Validate: Read one file per module to confirm understanding.
```

### Anti-Patterns in Exploration

- **Reading every file**: Wastes context window. Use grep to find relevant files first.
- **Assuming from filenames**: `utils.ts` could contain anything. Read before claiming.
- **Trusting comments over code**: Comments lie. Code is the source of truth.
- **Skipping tests**: Test files reveal intended behavior and edge cases.

## Provenance in Practice: Financial Research

```python
RESEARCH_PROMPT = """Research {company_name} and provide:
1. Current revenue and growth rate
2. Key competitors
3. Recent strategic moves

For EACH fact, you MUST provide:
- The source (document, web search, or training knowledge)
- If from training knowledge, state this explicitly and flag as "verify before use"
- If from web search, include the URL and access date
- Your confidence (1-5)

Format:
CLAIM: [statement]
SOURCE: [type] — [reference]
CONFIDENCE: [1-5]
VERIFY: [yes/no]
"""
```

## When to Use

- Financial analysis where claims drive investment decisions
- Legal document review requiring citation trails
- Any pipeline output that will be reviewed by compliance
- Onboarding to an unfamiliar codebase before making changes
- Research tasks where Claude mixes retrieved and training data

## Common Mistakes

1. **No source distinction**: Treating all of Claude's output as equally reliable, regardless of source
2. **Missing retrieval dates**: Web search results become stale. Without dates, you cannot assess freshness
3. **Skipping the exploration protocol**: Making claims about a codebase based on filenames and assumptions
4. **Inference chains without base tracking**: An inference is only as reliable as its weakest base claim
5. **Trusting training knowledge for mutable facts**: Anything that can change (company size, API versions, prices) must be verified from current sources
6. **No escalation path**: Every provenance system needs a "not sure, ask a human" escape valve

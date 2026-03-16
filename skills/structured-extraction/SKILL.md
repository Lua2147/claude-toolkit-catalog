---
name: structured-extraction
description: Few-shot prompting patterns for financial/legal data extraction and validation-retry loops for structured output quality. Maps to CCA Domain 4.
---

# Structured Extraction

## Overview

Patterns for extracting structured data from unstructured text using Claude. Covers few-shot prompting for consistent extraction, schema enforcement via tool_choice, and validation-retry loops for production reliability.

## Few-Shot Extraction Pattern

### The Template

Provide 2-3 examples that demonstrate the exact output format, edge cases, and how to handle missing data.

```python
EXTRACTION_PROMPT = """Extract financial metrics from the text below.

## Examples

Input: "Revenue grew 12% YoY to $4.2B in Q3 2025, with operating margin expanding to 18.5%."
Output:
```json
{
  "revenue": {"value": 4200000000, "currency": "USD", "period": "Q3 2025", "growth_yoy": 0.12},
  "operating_margin": {"value": 0.185, "period": "Q3 2025"},
  "net_income": null
}
```

Input: "The company reported a net loss of EUR 15M for FY2024."
Output:
```json
{
  "revenue": null,
  "operating_margin": null,
  "net_income": {"value": -15000000, "currency": "EUR", "period": "FY2024", "growth_yoy": null}
}
```

## Rules
- Use null for metrics not mentioned in the text
- Normalize all monetary values to raw numbers (no abbreviations)
- Negative values for losses
- growth_yoy as decimal (0.12 not 12%)

## Input
{text}
"""
```

### Why Few-Shot Works for Extraction

- Claude matches the output structure of examples, not just the instruction
- Edge cases in examples (null fields, negative values, currency handling) are replicated
- 2-3 examples is the sweet spot: fewer risks inconsistency, more wastes tokens

## Schema Enforcement via tool_choice

Force Claude to return structured data by defining a tool and requiring its use:

```python
extract_tool = {
    "name": "save_financial_data",
    "description": "Save extracted financial metrics. Call this with the extracted data.",
    "input_schema": {
        "type": "object",
        "properties": {
            "company_name": {"type": "string"},
            "metrics": {
                "type": "array",
                "items": {
                    "type": "object",
                    "properties": {
                        "name": {"type": "string", "enum": ["revenue", "ebitda", "net_income", "operating_margin"]},
                        "value": {"type": "number"},
                        "currency": {"type": "string"},
                        "period": {"type": "string"},
                        "source_sentence": {"type": "string"}
                    },
                    "required": ["name", "value", "period", "source_sentence"]
                }
            }
        },
        "required": ["company_name", "metrics"]
    }
}

response = client.messages.create(
    model="claude-sonnet-4-20250514",
    tools=[extract_tool],
    tool_choice={"type": "tool", "name": "save_financial_data"},
    messages=[{"role": "user", "content": f"Extract financial data:\n\n{document}"}]
)
extracted = response.content[0].input  # Guaranteed to match schema
```

## Validation-Retry Loop

### The Pattern

```python
import json
from jsonschema import validate, ValidationError

MAX_RETRIES = 3
schema = { ... }  # JSON Schema for expected output

for attempt in range(MAX_RETRIES):
    response = client.messages.create(
        model="claude-sonnet-4-20250514",
        messages=messages
    )

    try:
        data = json.loads(response.content[0].text)
        validate(instance=data, schema=schema)

        # Business logic validation
        errors = []
        for metric in data["metrics"]:
            if metric["value"] == 0 and "zero" not in metric.get("source_sentence", "").lower():
                errors.append(f"{metric['name']}: value is 0 but source doesn't mention zero")

        if errors:
            raise ValueError("; ".join(errors))

        break  # Valid extraction

    except (json.JSONDecodeError, ValidationError, ValueError) as e:
        if attempt == MAX_RETRIES - 1:
            raise  # Final attempt failed
        # Feed error back for self-correction
        messages.append({"role": "assistant", "content": response.content[0].text})
        messages.append({"role": "user", "content": f"Extraction error: {e}\n\nFix and try again."})
```

### Validation Layers

1. **Schema validation**: Does the JSON match the expected structure?
2. **Type validation**: Are numbers actually numeric, dates parseable?
3. **Business logic**: Are values in reasonable ranges? Do cross-references match?
4. **Source grounding**: Can each extracted value be traced to a source sentence?

## Legal Document Extraction

```python
# Pattern for extracting contract terms
LEGAL_PROMPT = """Extract key terms from this contract clause.

For each term found, provide:
- term_type: one of [termination_notice, liability_cap, payment_terms, governing_law, indemnification]
- value: the specific value or condition
- parties_affected: which parties this applies to
- source_text: exact quote from the contract

If a standard term type is not present in the clause, omit it. Do not infer terms not explicitly stated.

Clause:
{clause_text}
"""
```

## When to Use

- Processing financial filings (10-K, 10-Q, earnings transcripts)
- Extracting terms from legal documents (contracts, NDAs, LOIs)
- Parsing structured data from emails or PDFs
- Building enrichment pipelines (raw text -> structured records)

## Common Mistakes

1. **Zero-shot extraction**: Skipping examples leads to inconsistent output formats across documents
2. **No null handling in examples**: If examples never show null/missing fields, Claude invents data to fill gaps
3. **Missing source grounding**: Without `source_sentence`, hallucinated values are undetectable
4. **Infinite retry**: Always cap retries at 3 — if schema fails 3 times, the input is likely malformed
5. **Trusting tool_choice alone**: Schema enforcement catches structural errors but not semantic ones — always validate business logic too

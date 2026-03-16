---
name: context-reliability
description: Progressive summarization traps, lost-in-the-middle mitigation, persistent case facts, and scratchpad patterns for reliable context across long sessions. Maps to CCA Domain 5.
---

# Context Reliability

## Overview

Techniques to ensure Claude maintains accurate understanding of facts across long conversations, context window limits, and `/compact` operations. Covers the "lost in the middle" phenomenon, context preservation strategies, and scratchpad file patterns.

## The "Lost in the Middle" Problem

Claude (and all LLMs) attend most strongly to the **beginning** and **end** of their context window. Information in the middle receives less attention, leading to missed facts and contradictions.

### Mitigation: Bracket Critical Facts

Place the most important information at the START and END of your prompt:

```python
PROMPT = """
## CRITICAL CONTEXT (read first)
- Client: Acme Corp, $50M revenue, manufacturing sector
- Deal type: Sell-side M&A, targeting 6-8x EBITDA multiple
- Constraint: Must close before Q3 2026 tax changes

## DOCUMENTS TO ANALYZE
{long_document_content_here}

## REMINDER (same as above)
- Client: Acme Corp, $50M revenue, manufacturing sector
- Deal type: Sell-side M&A, targeting 6-8x EBITDA multiple
- Constraint: Must close before Q3 2026 tax changes

Based on the documents above and the client context, provide your analysis.
"""
```

### Mitigation: Chunked Processing

For documents longer than ~50K tokens, process in chunks and aggregate:

```python
def analyze_long_document(document: str, chunk_size: int = 30000) -> str:
    chunks = split_into_chunks(document, chunk_size, overlap=2000)

    chunk_analyses = []
    for i, chunk in enumerate(chunks):
        analysis = claude_analyze(f"""
        ## Document chunk {i+1}/{len(chunks)}
        {chunk}

        Extract all findings from this chunk. This is part of a larger document
        being processed in sections.
        """)
        chunk_analyses.append(analysis)

    # Final synthesis with all chunk results
    return claude_analyze(f"""
    ## Synthesize findings from {len(chunks)} document sections:
    {format_chunk_analyses(chunk_analyses)}

    Reconcile any conflicts between sections. Deduplicate findings.
    """)
```

## Progressive Summarization Traps

When Claude auto-summarizes during `/compact`, information degrades:

```
Full context    -> Summarized    -> Summarized again  -> Critical details lost
"EBITDA is       "Revenue ~$50M"   "Mid-size             Specific numbers
 $8.2M on                           company"              and metrics gone
 $50.3M revenue"
```

### Prevention: Persistent Case Facts Block

Create a facts block that survives summarization:

```markdown
## PERSISTENT FACTS (do not summarize or modify)
- Company: Acme Corp
- Revenue: $50.3M (FY2025)
- EBITDA: $8.2M (16.3% margin)
- Valuation target: 6-8x EBITDA ($49.2M - $65.6M)
- Key buyer: WidgetCo (LOI submitted 2026-02-15)
- Deadline: Close before 2026-09-30 (tax law change)
```

Place this at the top of your system prompt or CLAUDE.md. Instruct Claude to preserve it verbatim through summarization.

## Scratchpad File Patterns

### Writing State to Disk

For tasks spanning multiple `/compact` cycles, persist state to files:

```bash
# At a natural breakpoint, write progress
cat > .claude/state/deal-analysis.json << 'EOF'
{
  "task": "Acme Corp sell-side analysis",
  "phase": "comparable_analysis",
  "completed": [
    "financial_review",
    "market_sizing"
  ],
  "findings_so_far": [
    "Revenue growing 12% CAGR (3yr)",
    "EBITDA margin expanding: 14.1% -> 16.3%",
    "Customer concentration: top 3 = 45% of revenue"
  ],
  "next_steps": [
    "Run comparable company analysis",
    "Draft management presentation outline"
  ],
  "key_numbers": {
    "revenue": 50300000,
    "ebitda": 8200000,
    "target_multiple_low": 6,
    "target_multiple_high": 8
  }
}
EOF
```

### Reading State After Compact

```
# After /compact, Claude reads scratchpad to restore context
Read .claude/state/deal-analysis.json to understand current progress.
Continue from the "next_steps" listed there.
```

### Scratchpad Hygiene

- **Timestamp entries**: Add `"updated_at": "2026-03-15T10:30:00Z"` to detect stale state
- **Version the format**: Include `"schema_version": 1` so future sessions know how to parse it
- **Clean up when done**: Delete scratchpad files at task completion to avoid confusion in future sessions
- **One file per task**: Do not merge unrelated task states into a single scratchpad

## Context Window Budget

| Model | Context Window | Effective for Reliable Recall |
|-------|---------------|-------------------------------|
| Sonnet | 200K tokens | ~120K tokens (60%) |
| Opus | 200K tokens | ~120K tokens (60%) |
| Haiku | 200K tokens | ~100K tokens (50%) |

Plan to use only 50-60% of the context window for source material. Reserve the rest for instructions, examples, and Claude's reasoning.

## When to Use

- Multi-document analysis sessions exceeding 50K tokens
- Tasks spanning multiple `/compact` cycles
- Any workflow where specific numbers, dates, or names must be preserved exactly
- Long-running agent sessions (>30 minutes of continuous interaction)

## Common Mistakes

1. **Trusting middle context**: Placing critical facts only in the middle of a long prompt, where attention is weakest
2. **No persistent facts block**: Relying on Claude to remember specific numbers through summarization cycles
3. **Scratchpad without timestamps**: Stale scratchpad files from previous sessions mislead the current one
4. **Over-compacting**: Running `/compact` too frequently loses nuance that has not been written to scratchpad yet
5. **Single massive prompt**: Sending 150K tokens in one message instead of chunking and synthesizing
6. **Not validating after compact**: Always spot-check key facts after `/compact` — ask Claude to recite them

---
name: tool-design-patterns
description: Writing optimal tool descriptions, structured error responses, tool_choice configuration, and built-in tool catalog for Claude tool use. Maps to CCA Domain 2 (18%).
---

# Tool Design Patterns

## Overview

How to design tools that Claude uses effectively: writing descriptions that minimize misuse, returning structured errors that enable self-correction, controlling tool selection, and knowing the built-in tool catalog.

## Writing Optimal Tool Descriptions

### The Formula

Every tool description should contain: **action verb** + **what it operates on** + **boundary conditions** + **example**.

```json
{
  "name": "search_orders",
  "description": "Search customer orders by date range, status, or customer ID. Returns max 50 results per page. Use cursor parameter for pagination. Does NOT search archived orders older than 2 years — use search_archived_orders for those.",
  "input_schema": {
    "type": "object",
    "properties": {
      "customer_id": {
        "type": "string",
        "description": "UUID of the customer. Required unless date_range is provided."
      },
      "status": {
        "type": "string",
        "enum": ["pending", "shipped", "delivered", "cancelled"],
        "description": "Filter by order status. Omit to return all statuses."
      }
    }
  }
}
```

### Description Checklist

- Start with an action verb: "Search", "Create", "Delete", "Calculate"
- State what it does NOT do (boundary conditions)
- Mention side effects: "This will send an email to the customer"
- Include the return shape: "Returns an array of {id, name, status}"
- Note rate limits or cost: "Each call costs 1 API credit"

## Structured Error Responses

### The Four Error Categories

Always return errors with `is_error: true` and a category:

```json
{
  "is_error": true,
  "error_type": "input_validation",
  "message": "customer_id must be a valid UUID, got 'abc123'",
  "suggestion": "Use format: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
}
```

| Category | When | Claude's Expected Response |
|----------|------|--------------------------|
| `input_validation` | Bad parameters | Fix the input and retry |
| `permission` | Auth/authz failure | Inform user, do not retry |
| `not_found` | Resource missing | Try alternative lookup or inform user |
| `transient` | Timeout, rate limit | Wait and retry (max 3 attempts) |

### Why `is_error` Matters

When a tool returns `is_error: true`, Claude treats the result as a failure signal rather than content. Without this flag, Claude may interpret error messages as successful data and hallucinate on top of them.

## tool_choice Configuration

| Value | Behavior | Use When |
|-------|----------|----------|
| `auto` | Claude decides whether to use tools | Default for most conversations |
| `any` | Claude must use at least one tool | Forcing action (e.g., "always search before answering") |
| `{"type": "tool", "name": "X"}` | Claude must use tool X | Structured extraction, forced lookup |
| `none` | Claude cannot use tools | Analysis-only, summarization of prior results |

### Forcing Tool Use for Extraction

```python
response = client.messages.create(
    model="claude-sonnet-4-20250514",
    tools=[extract_financials_tool],
    tool_choice={"type": "tool", "name": "extract_financials"},
    messages=[{"role": "user", "content": f"Extract financials from: {document}"}]
)
# Claude MUST call extract_financials — guarantees structured output
```

## Built-in Tool Catalog

| Tool ID | Purpose | Key Details |
|---------|---------|-------------|
| `text_editor_20250429` | View, create, edit files | Line-based editing with `old_str`/`new_str` replacement |
| `web_search_20250305` | Search the web | Returns snippets, Claude synthesizes answer |
| `code_execution_20250522` | Run code in sandbox | Python, JS/TS execution with stdout/stderr capture |

### Enabling Built-in Tools

```python
response = client.messages.create(
    model="claude-sonnet-4-20250514",
    tools=[
        {"type": "text_editor_20250429"},
        {"type": "web_search_20250305"},
        # Plus your custom tools
        my_custom_tool,
    ],
    messages=[...]
)
```

## When to Use

- Designing MCP servers or custom tool integrations
- Building agentic pipelines where tool misuse causes cascading failures
- Optimizing tool descriptions after observing Claude misusing a tool
- Choosing between `tool_choice` modes for different pipeline stages

## Common Mistakes

1. **Vague descriptions**: "Handles orders" gives Claude no guidance on when to use it vs. other tools
2. **Missing boundary conditions**: Not stating what the tool cannot do leads to misuse
3. **Unstructured errors**: Returning plain strings instead of `is_error` objects causes Claude to treat errors as data
4. **Over-constraining tool_choice**: Using `{"type": "tool", "name": "X"}` when `auto` would produce better results through reasoning
5. **Ignoring parameter descriptions**: Claude reads parameter-level descriptions — empty ones waste an optimization opportunity
6. **Too many tools**: Beyond 15-20 tools, Claude's selection accuracy degrades. Group related operations into fewer tools with mode parameters

---
name: claude-code-config-advanced
description: Path-specific CLAUDE.md rules with YAML frontmatter globs, plan mode vs direct execution decision framework, and iterative refinement patterns. Maps to CCA Domain 3.
---

# Claude Code Advanced Configuration

## Overview

Advanced configuration techniques for Claude Code: scoping instructions to specific file paths using glob patterns, choosing between plan mode and direct execution, and structured iteration patterns for complex tasks.

## Path-Specific Rules with YAML Frontmatter

### Glob Scoping in CLAUDE.md

Rules in CLAUDE.md can be scoped to specific file paths using YAML frontmatter:

```markdown
---
globs: ["src/api/**/*.ts"]
---

# API Layer Rules

- All API handlers must validate input with Zod schemas
- Return consistent envelope: `{ data, error, meta }`
- Log request/response with correlation ID
- Never throw raw errors — wrap in AppError
```

```markdown
---
globs: ["*.test.ts", "*.spec.ts", "__tests__/**"]
---

# Test File Rules

- Use describe/it blocks, not test()
- One assertion per test case
- Mock at boundaries only (HTTP, DB, filesystem)
- Name pattern: should_[expected]_when_[condition]
```

### Glob Pattern Reference

| Pattern | Matches |
|---------|---------|
| `src/**/*.ts` | All .ts files under src/ recursively |
| `*.config.{js,ts}` | Config files in root with .js or .ts extension |
| `!**/node_modules/**` | Exclude node_modules |
| `src/api/**` | Everything under src/api/ |
| `migrations/*.sql` | SQL files directly in migrations/ |

### Layered CLAUDE.md

Claude Code merges instructions from multiple CLAUDE.md files:

```
repo-root/CLAUDE.md          # Global project rules
repo-root/src/CLAUDE.md      # Source code rules
repo-root/src/api/CLAUDE.md  # API-specific rules (highest priority)
~/.claude/CLAUDE.md           # User global rules (always loaded)
```

Rules closer to the working file take precedence. Use this for monorepo structures where different packages have different conventions.

## Plan Mode vs Direct Execution

### Decision Framework

| Criterion | Plan Mode | Direct Execution |
|-----------|-----------|-----------------|
| Files affected | >3 files | 1-3 files |
| Familiarity | Unfamiliar codebase | Well-known codebase |
| Risk | Cross-cutting change | Isolated change |
| Reversibility | Hard to undo | Easy to revert |
| Dependencies | Multiple interacting systems | Single module |

### Using Plan Mode

```
# Enter plan mode explicitly
/plan

# Or use the shift+tab toggle in Claude Code CLI

# Plan mode outputs:
# 1. Analysis of current state
# 2. Numbered step list
# 3. Files to be modified
# 4. Risks and assumptions
# Claude does NOT make changes until you approve
```

### When to Skip Plan Mode

- Single file bug fixes with a clear root cause
- Adding a new test for existing code
- Updating a config value
- Formatting or linting fixes

## Iterative Refinement Patterns

### The Interview Pattern

Use when requirements are ambiguous. Claude asks clarifying questions before acting.

```markdown
# In CLAUDE.md or system prompt:
Before implementing any feature request:
1. Restate what you understand the requirement to be
2. List 2-3 assumptions you are making
3. Ask about any ambiguity before writing code
4. Only proceed after the user confirms
```

### Test-Driven Iteration

```
Step 1: Write a failing test that captures the requirement
Step 2: Run the test — confirm it fails for the right reason
Step 3: Implement the minimum code to pass the test
Step 4: Run the test — confirm it passes
Step 5: Refactor if needed, re-run tests
```

This gives Claude a tight feedback loop. Each iteration is verifiable.

### Validation-Retry Loop

```python
MAX_RETRIES = 3
for attempt in range(MAX_RETRIES):
    result = claude_generate(prompt)
    errors = validate(result)
    if not errors:
        break
    prompt = f"Previous output had errors:\n{errors}\n\nFix and regenerate."
```

### Progressive Complexity

For large tasks, start simple and layer complexity:

```
Round 1: "Create a basic Express server with health check endpoint"
Round 2: "Add authentication middleware with JWT"
Round 3: "Add rate limiting and CORS configuration"
Round 4: "Add error handling middleware and structured logging"
```

Each round builds on verified working code.

## When to Use

- Setting up a new project with path-specific coding standards
- Deciding whether to use plan mode for a given task
- Breaking down a large feature into iterative Claude interactions
- Configuring monorepo CLAUDE.md hierarchies

## Common Mistakes

1. **Glob too broad**: `**/*` matches everything and dilutes the rule — scope narrowly
2. **Conflicting rules**: Two CLAUDE.md files giving opposite instructions for the same path — the closer file wins, but confusion remains
3. **Always using plan mode**: For trivial changes, plan mode adds overhead without value
4. **Never using plan mode**: For cross-cutting changes, skipping planning leads to partial implementations and missed files
5. **No verification step**: Iterative refinement without running tests or validation between rounds accumulates errors

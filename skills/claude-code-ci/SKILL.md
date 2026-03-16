---
name: claude-code-ci
description: Running Claude Code in CI pipelines — non-interactive mode, stream-json output, GitHub Actions integration, and PR review automation. Maps to CCA Domain 3.
---

# Claude Code in CI

## Overview

How to run Claude Code as a non-interactive tool in CI/CD pipelines. Covers the `claude -p` interface, output parsing, GitHub Actions integration, and common automation patterns like PR review and test generation.

## Non-Interactive Mode

### Basic Invocation

```bash
# Single prompt, streaming JSON output
claude -p "Review this diff for security issues" --output-format stream-json

# Pipe input via stdin
git diff HEAD~1 | claude -p "Review this diff" --output-format stream-json

# With a specific model
claude -p "Generate unit tests for src/auth.ts" --model claude-sonnet-4-20250514
```

### Output Formats

| Format | Use Case |
|--------|----------|
| `text` | Human-readable output (default) |
| `json` | Single JSON object on completion |
| `stream-json` | Newline-delimited JSON events as they arrive |

### stream-json Event Types

```jsonl
{"type": "assistant", "content": "Looking at the diff..."}
{"type": "tool_use", "tool": "Read", "input": {"file_path": "/src/auth.ts"}}
{"type": "tool_result", "output": "...file contents..."}
{"type": "result", "content": "Found 2 issues:\n1. ..."}
```

Parse the final `result` event for the actionable output.

## GitHub Actions Integration

### PR Review Workflow

```yaml
name: Claude PR Review
on:
  pull_request:
    types: [opened, synchronize]

jobs:
  review:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      pull-requests: write
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Install Claude Code
        run: npm install -g @anthropic-ai/claude-code

      - name: Run review
        env:
          ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}
        run: |
          DIFF=$(git diff origin/main...HEAD)
          REVIEW=$(echo "$DIFF" | claude -p "Review this PR diff. Focus on: bugs, security issues, missing error handling. Output as markdown." --output-format text)
          gh pr comment ${{ github.event.pull_request.number }} --body "$REVIEW"
        env:
          GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

### Test Generation on PR

```yaml
      - name: Generate missing tests
        env:
          ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}
        run: |
          CHANGED=$(git diff --name-only origin/main...HEAD -- '*.ts' '*.tsx')
          claude -p "Generate unit tests for these changed files: $CHANGED. Write tests to the appropriate __tests__ directories." --output-format text
```

## Key Flags for CI

| Flag | Purpose |
|------|---------|
| `-p "prompt"` | Non-interactive single prompt mode |
| `--output-format` | Control output format (text, json, stream-json) |
| `--model` | Override default model |
| `--max-turns` | Limit agentic loop iterations (prevents runaway) |
| `--allowedTools` | Restrict which tools Claude can use |
| `--disallowedTools` | Block specific tools (e.g., block Bash in review-only jobs) |

### Safety in CI

```bash
# Read-only review: block file writes and shell access
claude -p "Review src/ for bugs" \
  --allowedTools "Read,Glob,Grep" \
  --output-format json

# Limit iterations to prevent infinite loops
claude -p "Fix the failing test" --max-turns 10
```

## Parsing CI Output

```python
import json
import subprocess

result = subprocess.run(
    ["claude", "-p", "Analyze src/api.ts for N+1 queries", "--output-format", "json"],
    capture_output=True, text=True
)
output = json.loads(result.stdout)
# output["result"] contains the final response text
# output["cost"] contains token usage

if "N+1" in output["result"]:
    sys.exit(1)  # Fail the CI check
```

## When to Use

- Automated PR review on every push
- Pre-merge test generation for changed files
- Migration script validation before deploy
- Documentation freshness checks
- Security scanning as a CI gate

## Common Mistakes

1. **Missing `--output-format`**: Default text output is hard to parse in scripts — use `json` or `stream-json`
2. **No `--max-turns` in CI**: Without a turn limit, an agentic loop can run indefinitely and burn credits
3. **Exposing API keys**: Always use GitHub Secrets, never hardcode keys in workflow files
4. **Not restricting tools**: In review-only jobs, block Write/Edit/Bash to prevent accidental modifications
5. **Ignoring exit codes**: `claude -p` returns non-zero on failure — check `$?` or use `set -e`
6. **Large diffs as input**: Diffs over 100KB may exceed context — filter to relevant files first

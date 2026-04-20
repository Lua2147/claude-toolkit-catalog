---
description: Run Lehmann-style self-audit on CLAUDE.md + MEMORY.md + rules — recommend cuts (user approves before deletion)
allowed-tools: Read, Grep, Glob, Write
---

Audit scope: $ARGUMENTS (if empty, audit all: ~/.claude/CLAUDE.md + ~/.claude/projects/-Users-mundiprinceps-Mundi-Princeps/memory/MEMORY.md + ~/.claude/rules/*.md + project CLAUDE.md)

For every rule, check against Lehmann's 5 filters:
1. **Relevance** — does this apply to current work domains?
2. **Freshness** — based on now-obsolete model behavior?
3. **Model-version** — written for a model we no longer use?
4. **Redundancy** — overlaps with another rule?
5. **Over-constraining** — prevents better output?

Output:
- Structured report at `docs/knowledge-base/outputs/claude-md-audit-YYYY-MM-DD.md`
- Per-rule verdict: KEEP | CUT | MERGE-WITH-X | UPDATE | FLAG-FOR-USER
- Summary: total rules, proposed cuts, estimated % reduction
- DO NOT apply cuts automatically — wait for user approval

Done. Three files created at `.claude/skills/stagehand/`:

**`SKILL.md`** — Quick reference with init pattern, core API (act/extract/observe), singleton pattern, navigation fallback, security enforcement, and Context7 documentation pointers.

**`references/patterns.md`** — Deep patterns: CDP connection + Chrome lifecycle, Zod extraction schemas, error recovery, screenshot resizing with sharp, security blocklist, and 3 anti-patterns (re-init per operation, missing networkidle fallback, using Sonnet for Stagehand internals).

**`references/workflows.md`** — CLI-to-Claude-Agent-SDK bridge architecture, multi-step automation checklist, CDP network interception (the LinkedIn/SalesNav pattern), graceful shutdown for both in-process and cross-process scenarios, adding new CLI commands, and the "don't stuff multiple actions into one act()" anti-pattern.
All three files created. Here's what was generated:

**`.claude/skills/claude-agent-sdk/`**

- **`SKILL.md`** — Quick reference covering the `query()` API, message event types, system prompt presets, and both single-turn and multi-turn patterns drawn from `agent-browse.ts`

- **`references/patterns.md`** — Deep dive into message event handling, async generator gating (the `shouldPromptUser` flag pattern), tool use inspection with proper TypeScript casting, error handling for `is_error` tool results, and two critical anti-patterns (yielding before `result` fires, confusing `type: "user"` tool results with human input)

- **`references/workflows.md`** — Full interactive browser automation loop (agent-browse pattern), headless autonomous agent pattern (for Ralph-style server runs), graceful shutdown with SIGINT/SIGTERM, and a copyable new-agent checklist

All examples are pulled directly from `apps/agent-browse/agent-browse.ts`. Cross-references point to the **typescript**, **playwright**, **stagehand**, and **python** skills where relevant.
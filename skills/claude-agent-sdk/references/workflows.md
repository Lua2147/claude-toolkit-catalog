# Claude Agent SDK — Workflows Reference

## Contents
- Browser automation agent (agent-browse pattern)
- Autonomous scripted agent (Ralph Wiggum pattern)
- Graceful shutdown
- Process signal handling
- New agent checklist

---

## Browser Automation Agent (agent-browse Pattern)

The full interactive loop used in `apps/agent-browse/agent-browse.ts`:

```typescript
import { query } from '@anthropic-ai/claude-agent-sdk';

let shouldPromptUser = false;
let conversationActive = true;

async function* generateMessages(initialPrompt: string | null) {
  if (initialPrompt) {
    yield { type: "user" as const, message: { role: "user" as const, content: initialPrompt }, parent_tool_use_id: null, session_id: "default" };
  }
  while (conversationActive) {
    while (!shouldPromptUser && conversationActive) {
      await new Promise(r => setTimeout(r, 100));
    }
    if (!conversationActive) break;
    shouldPromptUser = false;
    const input = await getUserInput();
    if (input === 'exit') { conversationActive = false; break; }
    yield { type: "user" as const, message: { role: "user" as const, content: input }, parent_tool_use_id: null, session_id: "default" };
  }
}

const q = query({
  prompt: generateMessages(process.argv.slice(2).join(' ') || null),
  options: {
    systemPrompt: { type: 'preset', preset: 'claude_code', append: BROWSER_INSTRUCTIONS },
    maxTurns: 100,
    cwd: process.cwd(),
    model: "sonnet",
    executable: "node",
  },
});

for await (const message of q) {
  if (message.type === 'assistant') {
    const text = message.message?.content.find((c: any) => c.type === 'text');
    if (text && 'text' in text) console.log('Claude:', text.text);
    message.message?.content.filter((c: any) => c.type === 'tool_use')
      .forEach((t: any) => console.log(`Tool: ${t.name}`, t.input));
  }
  if (message.type === 'user' && Array.isArray(message.message?.content)) {
    (message.message.content as any[])
      .filter(c => c.type === 'tool_result' && c.is_error)
      .forEach(c => console.error('Error:', c.content));
  }
  if (message.type === 'result') shouldPromptUser = true;
}
```

For browser automation commands, agent-browse calls `tsx src/cli.ts <cmd>` via Bash tool — Claude doesn't control Stagehand directly, it issues CLI commands that Stagehand executes. See the **stagehand** skill for Stagehand-specific patterns.

---

## Autonomous Scripted Agent (Headless / No Human in Loop)

For automated runs (CI, server-side, Ralph-style):

```typescript
import { query } from '@anthropic-ai/claude-agent-sdk';

async function runTask(task: string, projectPath: string): Promise<void> {
  const q = query({
    prompt: task,  // single string = single-turn with tool loop
    options: {
      maxTurns: 20,
      cwd: projectPath,
      model: "sonnet",
      executable: "node",
    },
  });

  for await (const message of q) {
    if (message.type === 'assistant') {
      const text = message.message?.content.find((c: any) => c.type === 'text');
      if (text && 'text' in text) {
        console.log(text.text);
      }
    }
  }
}

await runTask("Fix all TypeScript errors in src/", "/path/to/project");
```

Set `maxTurns` low for scripted tasks — a runaway agent with no ceiling will burn tokens indefinitely. 10-20 turns is enough for most single tasks.

> For the Python equivalent (Ralph Wiggum uses the `anthropic` SDK directly with a manual tool loop), see the **python** skill.

---

## Graceful Shutdown

Always clean up external resources before exit. Agent-browse shuts down the Stagehand browser:

```typescript
async function cleanup() {
  try {
    // Kill any persistent subprocess (browser, server, etc.)
    const proc = spawn('tsx', ['src/cli.ts', 'close'], { stdio: 'inherit' });
    await new Promise<void>(resolve => {
      const timeout = setTimeout(() => { proc.kill(); resolve(); }, 10_000);
      proc.on('close', () => { clearTimeout(timeout); resolve(); });
    });
  } catch {
    // Ignore cleanup errors — process is terminating
  }
}

process.on('SIGINT', async () => { await cleanup(); process.exit(0); });
process.on('SIGTERM', async () => { await cleanup(); process.exit(0); });
main().catch(async (err) => { console.error(err); await cleanup(); process.exit(1); });
```

**Always register SIGINT and SIGTERM.** Without them, Ctrl+C leaves browsers/servers running, consuming resources until the OS kills them.

---

## WARNING: Missing `cwd` in Options

**The Problem:**

```typescript
// BAD — cwd defaults to SDK process directory, not your project
query({ prompt: "Run the tests", options: { model: "sonnet" } })
```

**Why This Breaks:**
The Bash tool resolves paths relative to `cwd`. If `cwd` is the SDK install directory, `npm test` runs in the wrong place. File tools (Read, Write, Glob) silently operate on wrong paths.

**The Fix:**
```typescript
options: { cwd: process.cwd(), model: "sonnet" }  // or an absolute project path
```

---

## WARNING: Blocking the Generator with `await` Before Yielding

**The Problem:**

```typescript
// BAD — awaits a slow operation before the first yield
async function* messages() {
  const data = await fetchSomeLargeDataset();  // blocks everything
  yield { type: "user", message: { role: "user", content: data }, ... };
}
```

**Why This Breaks:**
The SDK starts consuming the generator immediately. A blocking `await` before the first yield delays agent startup. For slow data sources, pre-fetch outside the generator and close over the result.

**The Fix:**
```typescript
const data = await fetchSomeLargeDataset();  // pre-fetch
async function* messages() {
  yield { type: "user", message: { role: "user", content: data }, ... };
}
```

---

## New Agent Checklist

Copy and track progress:

- [ ] Set `cwd` to project root (absolute path)
- [ ] Set `maxTurns` — 100 for interactive, 10-20 for scripted
- [ ] Choose `model: "sonnet"` (default) or `"opus"` for hard reasoning tasks
- [ ] Register `SIGINT`/`SIGTERM` handlers for cleanup
- [ ] Handle `is_error` tool results in the message loop
- [ ] Gate human input on `type === 'result'` event (multi-turn only)
- [ ] Keep `append` instructions under ~200 tokens
- [ ] Test with `exit`/`quit` to verify graceful shutdown

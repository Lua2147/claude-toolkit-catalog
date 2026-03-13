# Claude Agent SDK — Patterns Reference

## Contents
- Message event handling
- Async generator input (multi-turn)
- System prompt customization
- Tool use inspection
- Error handling
- Anti-patterns

---

## Message Event Handling

The `query()` iterator yields three event types. Match on `type` before accessing fields:

```typescript
for await (const message of q) {
  switch (message.type) {
    case 'assistant': {
      // Claude's response — may contain text, tool_use, or both
      const content = message.message?.content ?? [];
      const text = content.find(c => c.type === 'text');
      const tools = content.filter(c => c.type === 'tool_use');
      break;
    }
    case 'user': {
      // Tool results returned to the model — NOT human input
      const content = message.message?.content;
      if (Array.isArray(content)) {
        const results = content.filter((c: any) => c.type === 'tool_result');
      }
      break;
    }
    case 'result': {
      // Turn complete — this is when to prompt the human for next input
      shouldPromptUser = true;
      break;
    }
  }
}
```

**Why `user` type contains tool results:** The SDK mirrors the Claude API message format. Tool results travel back to Claude as `user`-role messages. Don't confuse this with human input — human messages also use `type: "user"` when yielded from the generator, but `message.role === "user"` with string `content`.

---

## Async Generator Input (Multi-Turn)

The `prompt` parameter accepts either a string (single-turn) or an async generator (multi-turn). The agent-browse pattern:

```typescript
async function* generateMessages() {
  // Yield initial task
  yield {
    type: "user" as const,
    message: { role: "user" as const, content: initialPrompt },
    parent_tool_use_id: null,
    session_id: "default"
  };

  // Gate on a flag — only yield when the previous turn finished
  while (conversationActive) {
    while (!shouldPromptUser && conversationActive) {
      await new Promise(resolve => setTimeout(resolve, 100));  // poll until ready
    }
    shouldPromptUser = false;

    const input = await getUserInput();
    if (input === 'exit') { conversationActive = false; break; }

    yield {
      type: "user" as const,
      message: { role: "user" as const, content: input },
      parent_tool_use_id: null,
      session_id: "default"
    };
  }
}
```

Set `shouldPromptUser = true` inside the `result` branch of your message loop. This prevents yielding the next human message before Claude finishes the current turn.

---

## System Prompt Customization

**Preset only** — gives Claude Code's full tool suite:
```typescript
options: {
  systemPrompt: { type: 'preset', preset: 'claude_code' }
}
```

**Preset + append** — extend with domain-specific instructions (agent-browse pattern):
```typescript
options: {
  systemPrompt: {
    type: 'preset',
    preset: 'claude_code',
    append: `\n\n# Browser Automation via CLI\n\nFor browser tasks, call:\n- tsx src/cli.ts navigate <url>\n- tsx src/cli.ts act "<action>"`
  }
}
```

Keep appended instructions short — they consume tokens on every turn. Use bullet lists, not paragraphs.

---

## Tool Use Inspection

Tool uses arrive in `assistant` messages. Tool names and inputs are typed as `any` — cast explicitly:

```typescript
interface ToolUse {
  type: 'tool_use';
  name: string;
  id: string;
  input: Record<string, unknown>;
}

if (message.type === 'assistant') {
  const toolUses = (message.message?.content ?? []).filter(
    (c): c is ToolUse => c.type === 'tool_use'
  );
  for (const tool of toolUses) {
    console.log(`[${tool.name}]`, JSON.stringify(tool.input, null, 2));
  }
}
```

---

## Error Handling

Tool errors come as `tool_result` items with `is_error: true` in `user` messages:

```typescript
if (message.type === 'user' && Array.isArray(message.message?.content)) {
  for (const item of message.message.content as any[]) {
    if (item.type === 'tool_result' && item.is_error) {
      const text = typeof item.content === 'string'
        ? item.content
        : (item.content?.find((c: any) => c.type === 'text')?.text ?? 'Unknown error');
      console.error('Tool error:', text);
    }
  }
}
```

`content` can be a `string` OR an array — always normalize before reading.

---

## WARNING: Yielding Next Message Before `result`

**The Problem:**

```typescript
// BAD — races against Claude's in-progress tool calls
async function* messages() {
  yield userMessage1;
  const input = await getUserInput();  // immediately waits for user
  yield { ...input };
}
```

**Why This Breaks:**
Claude may still be executing tools when you yield the next message. The SDK receives the new user turn mid-flight, causing undefined behavior or dropped tool results.

**The Fix:**
Gate on the `result` event:

```typescript
// GOOD — only ask user AFTER 'result' fires
case 'result':
  shouldPromptUser = true;
  break;
```

---

## WARNING: Treating `type: "user"` as Human Input

**The Problem:**
Both tool results AND human messages use `type: "user"` in the event stream.

**The Fix:**
Distinguish by `message.content` shape:
- Human input: `content` is a `string`
- Tool results: `content` is an `array` containing `{ type: 'tool_result', ... }` items

---

## Options Reference

```typescript
query({
  prompt: string | AsyncGenerator,
  options: {
    systemPrompt?: { type: 'preset', preset: 'claude_code', append?: string }
    maxTurns?: number       // default: unlimited; set 100 for interactive, 10 for scripted
    cwd?: string            // working directory for file/bash tools
    model?: 'sonnet' | 'opus' | 'haiku'
    executable?: 'node'     // runtime for tool execution
  }
})
```

`cwd` is critical when the agent uses `Bash` or file tools — without it, paths resolve relative to the SDK's process, not your project.

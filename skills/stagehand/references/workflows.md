# Stagehand Workflows Reference

## Contents
- CLI bridge to Claude Agent SDK
- Multi-step automation workflow
- Network monitoring via CDP
- Graceful shutdown
- Adding new CLI commands
- Checklist: new automation task

---

## CLI Bridge to Claude Agent SDK

`agent-browse` exposes Stagehand as CLI commands returning JSON, which Claude (via Agent SDK) reads and acts on. This decouples the LLM orchestrator from the browser runtime.

```
Claude (Sonnet) → decides what to do
  → spawns: tsx src/cli.ts act "Click the search button"
  → reads JSON: { success: true, message: "...", screenshot: "/path/to/file.png" }
  → decides next step
```

**Entry point** (`agent-browse.ts`):
```typescript
import { query } from "@anthropic-ai/claude-agent-sdk";

const q = query({
  prompt: generateMessages(),  // async generator yields user inputs
  options: {
    systemPrompt: {
      type: 'preset',
      preset: 'claude_code',
      append: `
For browser automation, use these bash commands:
- tsx src/cli.ts navigate <url>
- tsx src/cli.ts act "<natural language action>"
- tsx src/cli.ts extract "<instruction>" '{"field": "string"}'
- tsx src/cli.ts observe "<query about page elements>"
- tsx src/cli.ts screenshot
- tsx src/cli.ts close
      `
    },
    maxTurns: 100,
    model: "sonnet",
  },
});

for await (const message of q) {
  if (message.type === 'assistant') process.stdout.write(renderMessage(message));
  if (message.type === 'result') promptNextInstruction();
}
```

See the **claude-agent-sdk** skill for full Agent SDK patterns.

---

## Multi-Step Automation Workflow

Pattern for long automation sequences (form fills, multi-page flows):

```typescript
async function runAutomation(steps: string[]): Promise<void> {
  const stagehand = await getStagehand();

  for (const step of steps) {
    try {
      await stagehand.act(step);
      const screenshot = await takeScreenshot(stagehand, PLUGIN_ROOT);
      console.log(JSON.stringify({ step, success: true, screenshot }));
    } catch (error) {
      // Recover: observe current state before retrying
      const elements = await stagehand.observe("interactive elements on this page");
      console.error(JSON.stringify({
        step,
        success: false,
        error: String(error),
        availableElements: elements.map(e => e.description),
      }));
      // Caller decides: retry, skip, or abort
      throw error;
    }
  }
}
```

Checklist for new automation task:
```
- [ ] Security: call getBlockedDomain(url) before any navigation
- [ ] Navigate with networkidle + domcontentloaded fallback
- [ ] Add 3s delay after navigation for JS hydration
- [ ] Use observe() if page structure is unknown before act()
- [ ] Wrap each act() in try-catch, log screenshot on failure
- [ ] Return JSON { success, message/error, screenshot } at every exit point
- [ ] Cleanup: call closeBrowser() on SIGINT/SIGTERM
```

---

## Network Monitoring via CDP

Use when you need to capture API calls made by the page (e.g., intercepting LinkedIn/SalesNav API responses):

```typescript
import { Stagehand } from "@browserbasehq/stagehand";

async function captureNetworkRequests(url: string, apiFilter: string) {
  const stagehand = await getStagehand();
  const page = stagehand.context.pages()[0];
  const client = page.mainFrame().session;

  const captured: Array<{ url: string; method: string; body?: string }> = [];
  const responses: Array<{ url: string; status: number; body: string }> = [];

  await client.send('Network.enable');

  client.on('Network.requestWillBeSent', (params: any) => {
    if (params.request.url.includes(apiFilter)) {
      captured.push({
        url: params.request.url,
        method: params.request.method,
        body: params.request.postData,
      });
    }
  });

  client.on('Network.responseReceived', async (params: any) => {
    if (params.response.url.includes(apiFilter)) {
      try {
        const { body } = await client.send<{ body: string }>('Network.getResponseBody', {
          requestId: params.requestId,
        });
        responses.push({
          url: params.response.url,
          status: params.response.status,
          body,
        });
      } catch {}  // Body not always available
    }
  });

  await page.goto(url, { waitUntil: 'networkidle' });

  return { requests: captured, responses };
}
```

**Use case in this codebase:** Capturing LinkedIn Sales Navigator API responses to extract search results without triggering bot detection. See `src/network-monitor.ts`.

---

## Graceful Shutdown

Two scenarios: in-process (same Node process) and cross-process (separate CLI invocations).

```typescript
// In-process: kill Chrome we started, skip if we attached to existing
async function closeBrowser() {
  if (stagehandInstance) {
    await stagehandInstance.close().catch(() => {});
    stagehandInstance = null;
  }

  if (chromeProcess && weStartedChrome) {
    chromeProcess.kill('SIGTERM');
    await new Promise(r => setTimeout(r, 1000));
    if (chromeProcess.exitCode === null) {
      chromeProcess.kill('SIGKILL');
    }
  }
}

// Cross-process: connect via CDP and close gracefully
async function closeExistingChrome(cdpPort: number) {
  try {
    const { webSocketDebuggerUrl } = await (
      await fetch(`http://127.0.0.1:${cdpPort}/json/version`)
    ).json();

    const temp = new Stagehand({
      env: "LOCAL",
      verbose: 0,
      model: "anthropic/claude-haiku-4-5-20251001",
      localBrowserLaunchOptions: { cdpUrl: webSocketDebuggerUrl },
    });
    await temp.init();
    await temp.close();
    await new Promise(r => setTimeout(r, 2000));
  } catch {}
}

// Always register signal handlers
process.on('SIGINT', async () => { await closeBrowser(); process.exit(0); });
process.on('SIGTERM', async () => { await closeBrowser(); process.exit(0); });
```

---

## Adding New CLI Commands

Pattern for extending `src/cli.ts`:

```typescript
// 1. Write the operation function
async function scroll(direction: 'up' | 'down', amount = 500) {
  try {
    const stagehand = await getStagehand();
    const page = stagehand.context.pages()[0];
    await page.evaluate((amt) => window.scrollBy(0, amt), direction === 'down' ? amount : -amount);
    const screenshot = await takeScreenshot(stagehand, PLUGIN_ROOT);
    return { success: true, message: `Scrolled ${direction} by ${amount}px`, screenshot };
  } catch (error) {
    return { success: false, error: error instanceof Error ? error.message : String(error) };
  }
}

// 2. Add to switch statement in main()
case 'scroll':
  result = await scroll(args[1] as 'up' | 'down', parseInt(args[2] ?? '500'));
  break;

// 3. Update system prompt in agent-browse.ts
// - tsx src/cli.ts scroll <up|down> [amount]
```

Validate: run `tsx src/cli.ts scroll down 300` — should return JSON with success and screenshot path.

---

## Anti-Pattern: Doing complex logic inside act()

**The Problem:**
```typescript
// BAD - Overcrowding a single act() instruction
await stagehand.act(`
  First find the search box, type "venture capital", then press enter,
  wait for results, find the first result, click it, scroll down,
  find the contact form, fill name as "John", email as "john@example.com",
  click submit, and verify the success message appears
`);
```

**Why This Breaks:** Stagehand's LLM handles one atomic action at a time. Multi-step instructions cause partial execution with no clear failure point.

**The Fix:**
```typescript
// GOOD - One action per act() call
await stagehand.act('Click in the search box');
await stagehand.act('Type "venture capital"');
await stagehand.act('Press Enter');
await page.waitForLoadState('networkidle');
await stagehand.act('Click the first search result');
// ... continue step by step
```

Each step is observable (screenshot), retryable, and debuggable independently.

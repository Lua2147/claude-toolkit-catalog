# Stagehand Patterns Reference

## Contents
- Initialization & CDP connection
- Extraction with Zod schemas
- Error handling
- Screenshot resizing
- Security enforcement
- Anti-patterns

---

## Initialization & CDP Connection

The `apps/agent-browse` pattern: find/launch Chrome once, reuse across all operations.

```typescript
// 1. Check for running Chrome on CDP port
const cdpPort = parseInt(fs.readFileSync('.cdp-port', 'utf8'));
let chromeReady = false;
try {
  const res = await fetch(`http://127.0.0.1:${cdpPort}/json/version`);
  chromeReady = res.ok;
} catch {}

// 2. Launch if needed
if (!chromeReady) {
  const chromePath = findLocalChrome();  // platform-aware detection
  chromeProcess = spawn(chromePath, [
    `--remote-debugging-port=${cdpPort}`,
    `--user-data-dir=${persistentProfileDir}`,
    '--window-size=1920,1080',
  ], { stdio: 'ignore', detached: false });

  // Poll until ready (max 30s)
  for (let i = 0; i < 60; i++) {
    try {
      if ((await fetch(`http://127.0.0.1:${cdpPort}/json/version`)).ok) break;
    } catch {}
    await new Promise(r => setTimeout(r, 500));
  }
}

// 3. Get WebSocket URL and connect Stagehand
const { webSocketDebuggerUrl } = await (
  await fetch(`http://127.0.0.1:${cdpPort}/json/version`)
).json();

const stagehand = new Stagehand({
  env: "LOCAL",
  verbose: 0,
  model: "anthropic/claude-haiku-4-5-20251001",
  localBrowserLaunchOptions: { cdpUrl: webSocketDebuggerUrl },
});
await stagehand.init();
```

**Why Haiku for Stagehand?** Act/extract calls happen on every browser interaction. Haiku is 20x cheaper than Sonnet with no quality difference for DOM reasoning tasks.

---

## Extraction with Zod Schemas

Always pass a schema for structured scraping — without it you get raw strings that need post-processing.

```typescript
import { z } from "zod";

// Flat extraction
const result = await stagehand.extract({
  instruction: "Extract the company name, CEO, and last funding round",
  schema: z.object({
    companyName: z.string(),
    ceo: z.string(),
    lastRound: z.object({
      amount: z.string(),
      date: z.string(),
      type: z.enum(["Seed", "Series A", "Series B", "Series C", "Growth"]),
    }).optional(),
  }),
});
// result.companyName — typed, no parsing needed

// List extraction
const leads = await stagehand.extract({
  instruction: "Extract all search result cards with name, title, company",
  schema: z.object({
    results: z.array(z.object({
      name: z.string(),
      title: z.string(),
      company: z.string(),
      profileUrl: z.string().url().optional(),
    }))
  }),
});
```

**When schema is optional:** Use raw extraction only for free-form content (emails, descriptions) where structure is unknown. Always validate the result before using it.

---

## Error Handling

All CLI commands return `{ success: boolean, ... }` — never throw past the boundary.

```typescript
async function act(action: string): Promise<{ success: boolean; message?: string; error?: string; screenshot?: string }> {
  try {
    const stagehand = await getStagehand();
    await stagehand.act(action);
    const screenshotPath = await takeScreenshot(stagehand, PLUGIN_ROOT);
    return { success: true, message: `Action completed: ${action}`, screenshot: screenshotPath };
  } catch (error) {
    return {
      success: false,
      error: error instanceof Error ? error.message : String(error),
    };
  }
}
```

**Recovery after act() failure:** Stagehand's LLM may fail to locate an element. Follow `act()` with `observe()` to get current interactive elements, then retry with more specific instruction.

```typescript
try {
  await stagehand.act("Click the login button");
} catch {
  const elements = await stagehand.observe("buttons and links on the page");
  // Log elements, refine instruction
  await stagehand.act(`Click the element labeled "${elements[0].description}"`);
}
```

---

## Screenshot Resizing

Claude's vision context has token costs proportional to image size. Always resize before passing to Claude.

```typescript
import sharp from "sharp";

async function takeScreenshot(stagehand: Stagehand, outputDir: string): Promise<string> {
  const page = stagehand.context.pages()[0];
  const raw = await page.screenshot({ type: 'png' });

  const metadata = await sharp(raw).metadata();
  let buffer = raw;
  if ((metadata.width ?? 0) > 2000 || (metadata.height ?? 0) > 2000) {
    buffer = await sharp(raw)
      .resize(2000, 2000, { fit: 'inside', withoutEnlargement: true })
      .png()
      .toBuffer();
  }

  const path = join(outputDir, `screenshot-${Date.now()}.png`);
  fs.writeFileSync(path, buffer);
  return path;
}
```

---

## Security Enforcement

```typescript
// security.ts — check before any navigate() or act() with URLs
const BLOCKED_DOMAINS = ['chase.com', 'mail.google.com', 'paypal.com', /* ... */];

export function getBlockedDomain(url: string): string | null {
  const hostname = new URL(url).hostname.toLowerCase();
  for (const domain of BLOCKED_DOMAINS) {
    if (hostname === domain || hostname.endsWith('.' + domain)) return domain;
  }
  return null;
}

// In navigate():
const blocked = getBlockedDomain(url);
if (blocked) return { success: false, error: `BLOCKED: navigation to ${blocked} is restricted` };

// In act() — scan action text for embedded URLs:
export function actionReferencesBlockedDomain(action: string): string | null {
  const urls = action.match(/https?:\/\/[^\s"'<>]+/gi) ?? [];
  for (const url of urls) {
    const blocked = getBlockedDomain(url);
    if (blocked) return blocked;
  }
  return null;
}
```

---

## Anti-Patterns

### WARNING: Re-initializing Stagehand per operation

**The Problem:**
```typescript
// BAD - New Stagehand on every CLI call
async function act(action: string) {
  const stagehand = new Stagehand({ ... });
  await stagehand.init();  // ~2-3 second overhead
  await stagehand.act(action);
  await stagehand.close();  // Session state lost
}
```

**Why This Breaks:**
1. Each `init()` takes 2-3 seconds — kills interactive UX
2. Closing after each call loses cookies, localStorage, auth state
3. Chrome process lifecycle becomes unpredictable

**The Fix:** Singleton pattern — one instance, keep alive, reuse across calls.

---

### WARNING: Blocking navigation without networkidle fallback

**The Problem:**
```typescript
// BAD - Hard fails on SPAs and slow pages
await page.goto(url, { waitUntil: 'networkidle', timeoutMs: 30000 });
```

**Why This Breaks:** SPAs with WebSocket connections or polling never reach `networkidle`. The navigation times out even though the page is fully loaded.

**The Fix:**
```typescript
// GOOD - Fallback to domcontentloaded
await page.goto(url, { waitUntil: 'networkidle', timeoutMs: 30000 })
  .catch(() => page.goto(url, { waitUntil: 'domcontentloaded', timeoutMs: 15000 }));
await new Promise(r => setTimeout(r, 3000));  // Let JS settle
```

---

### WARNING: Using GPT/Sonnet model for act/extract

**The Problem:**
```typescript
// BAD - Expensive model for routine DOM tasks
model: "anthropic/claude-sonnet-4-6"
```

**Why This Breaks:** Act/extract are called on every browser interaction. At Sonnet pricing, a 50-step automation costs 10-20x more than with Haiku, with no quality benefit for DOM tasks.

**The Fix:** `model: "anthropic/claude-haiku-4-5-20251001"` — reserve Sonnet for the orchestrating agent, not Stagehand internals.

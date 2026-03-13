# Playwright Workflows Reference

## Contents
- Adding a New E2E Test (Kadenwood)
- Writing a Python Scraper
- MCP Live Browser Automation
- Playwright Config (Multi-Browser)
- CI vs Local Execution
- Debugging Failures

---

## Adding a New E2E Test (Kadenwood)

Tests live in `apps/kadenwood/apps/dashboard/e2e/`. Auth is free via `storageState`.

Copy this checklist:
- [ ] Create `e2e/<feature>-<action>.spec.ts`
- [ ] Use `E2E_TEST_` prefix for all created data
- [ ] Set up data via `entity-factory.ts` (not via UI) when possible
- [ ] Clean up in `afterAll` or use service role bypass
- [ ] Run locally: `npx playwright test e2e/<your-file>.spec.ts --project=chromium`
- [ ] Confirm no `waitForTimeout` calls without a comment explaining why

```typescript
// e2e/tasks-crud.spec.ts — minimal working template
import { test, expect } from '@playwright/test';
import { createTask, deleteTask, generateUniqueName } from './fixtures/entity-factory';

test.describe('Tasks CRUD', () => {
  let taskId: string;
  const taskName = generateUniqueName('Task');

  test.beforeAll(async () => {
    const task = await createTask({ title: taskName });
    taskId = task.id;
  });

  test.afterAll(async () => {
    await deleteTask(taskId);
  });

  test('task appears in list', async ({ page }) => {
    await page.goto('/tasks');
    await page.waitForLoadState('networkidle');
    await expect(page.locator(`tr:has-text("${taskName}")`)).toBeVisible();
  });
});
```

---

## Writing a Python Scraper

For web scraping, use `playwright.async_api` with network interception instead of DOM scraping where possible — it's faster and more reliable.

```python
import asyncio
from playwright.async_api import async_playwright

async def scrape_with_interception(target_url: str, api_path: str) -> list[dict]:
    captured = []

    async with async_playwright() as p:
        browser = await p.chromium.launch(headless=False)  # headless=False helps avoid bot detection
        context = await browser.new_context(
            viewport={'width': 1920, 'height': 1080},
            user_agent='Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)...'
        )
        page = await context.new_page()

        async def handle_response(response):
            if api_path in response.url and response.status == 200:
                try:
                    data = await response.json()
                    captured.append(data)
                except Exception:
                    pass

        page.on('response', handle_response)

        await page.goto(target_url, wait_until='domcontentloaded')
        await page.wait_for_load_state('networkidle')

        # pagination: click next until exhausted
        while True:
            await page.wait_for_load_state('networkidle')
            next_btn = page.locator('button[aria-label="Go to next page"]').first
            if not await next_btn.count():
                break
            await next_btn.click()

        await browser.close()

    return captured

asyncio.run(scrape_with_interception('https://app.example.io/', '/api/v1/search'))
```

See the **python** skill for async patterns.

---

## MCP Live Browser Automation

Use `mcp__playwright__*` tools when you need to automate a browser within a Claude session (e.g., creating HeyReach campaigns that have no API).

**Workflow:**

1. `browser_navigate` — go to the URL
2. `browser_snapshot` — get accessibility tree (always before interacting)
3. `browser_click` or `browser_fill_form` — interact
4. `browser_snapshot` again — confirm state changed
5. `browser_take_screenshot` — capture result if needed

```
# Step 1: Navigate
mcp__playwright__browser_navigate { "url": "https://app.heyreach.io/campaigns/new" }

# Step 2: Inspect available elements
mcp__playwright__browser_snapshot {}

# Step 3: Fill form fields (use refs from snapshot)
mcp__playwright__browser_fill_form {
  "fields": [
    { "ref": "<ref from snapshot>", "value": "Campaign Name" }
  ]
}

# Step 4: Confirm and capture
mcp__playwright__browser_take_screenshot {}
```

**Critical rule**: ALWAYS snapshot after navigation before clicking. Element refs from a previous page are stale after navigation.

**When to use `browser_evaluate`**: JavaScript execution for things the accessibility tree doesn't expose.

```
mcp__playwright__browser_evaluate {
  "script": "return document.querySelector('[data-campaign-id]')?.dataset.campaignId"
}
```

---

## Playwright Config (Multi-Browser)

Kadenwood config at `apps/kadenwood/apps/dashboard/playwright.config.ts` handles M1/x64 headless shell detection:

```typescript
// Auto-detects ARM64 vs x64 headless shell
const localArm64 = `${cacheDir}/chromium_headless_shell-1208/chrome-headless-shell-mac-arm64/...`;
const localX64   = `${cacheDir}/chromium_headless_shell-1208/chrome-headless-shell-mac-x64/...`;
const executablePath = [localArm64, localX64].find(fs.existsSync);

// Setup project runs first; others depend on it
projects: [
  { name: 'setup', testMatch: /.*\.setup\.ts/ },
  { name: 'chromium', use: { storageState: 'e2e/.auth/user.json' }, dependencies: ['setup'] },
  { name: 'firefox',  use: { storageState: 'e2e/.auth/user.json' }, dependencies: ['setup'] },
]
```

Key `use` settings:
- `trace: 'retain-on-failure'` — trace viewer for debugging failures
- `screenshot: 'only-on-failure'` — keeps test runs fast
- `actionTimeout: 10000` — per-action limit (don't remove this)

---

## CI vs Local Execution

| Setting | Local | CI |
|---------|-------|---|
| `fullyParallel` | false | true |
| `workers` | 1 | 3 |
| `retries` | 0 | 2 |
| Browser | local Chrome (`channel: 'chrome'`) | headless Chromium |

Set `BASE_URL` env to run against staging or production:
```bash
BASE_URL=https://kadenwood-staging.vercel.app npx playwright test
```

---

## Debugging Failures

```bash
# Interactive UI mode — step through tests visually
npx playwright test --ui

# Run in headed mode (see the browser)
npx playwright test --headed

# Open trace viewer after a failure
npx playwright show-trace test-results/<test>/trace.zip

# Debug a single test with Playwright inspector
npx playwright test e2e/deal-crud.spec.ts --debug

# Take a screenshot mid-test (add to your test)
await page.screenshot({ path: 'debug.png' });
```

**Common failures:**

| Symptom | Likely Cause | Fix |
|---------|-------------|-----|
| `storageState not found` | Auth setup didn't run | Run `npx playwright test --project=setup` first |
| Locator timeout | UI changed, selector stale | Update selector; prefer `getByRole`/`getByLabel` |
| `networkidle` never fires | WebSocket or polling keeps connection open | Use `domcontentloaded` + explicit `waitForSelector` |
| Flaky timing failures | `waitForTimeout` without actual condition | Replace with `expect(...).toBeVisible()` |
| RLS blocks entity read | Anon key can't see test data | Use `service-role-admin.ts` helpers |

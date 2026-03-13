# Playwright Patterns Reference

## Contents
- Page Object Model
- Locator Strategies
- Test Data Management
- Auth State
- Network Interception (Python)
- Anti-Patterns

---

## Page Object Model

Kadenwood uses a class hierarchy: `BasePage → EntityListPage → {CompaniesPage, DealsPage, ...}`.

```typescript
// e2e/fixtures/page-objects.ts — the actual base class
export class BasePage {
  constructor(public page: Page) {}

  async goto(path: string) {
    await this.page.goto(path);
    await this.page.waitForLoadState('networkidle'); // waits for all XHR to settle
  }
}

export class EntityListPage extends BasePage {
  async openNewModal() {
    await this.page.keyboard.press('n'); // keyboard shortcut — faster than button click
    await this.page.waitForTimeout(500);
  }

  async getRowByName(name: string): Promise<Locator> {
    return this.page.locator(`tr:has-text("${name}")`).first();
  }
}

export class EntityModal extends BasePage {
  modal: Locator;
  constructor(page: Page) {
    super(page);
    this.modal = page.locator('div[role="dialog"]');
  }

  async fillField(labelText: string, value: string) {
    const label = this.modal.locator(`label:has-text("${labelText}")`).first();
    const input = label.locator('..').locator('input, textarea').first();
    await input.fill(value);
  }
}
```

---

## Locator Strategies

Prefer semantic locators — they survive UI refactors.

```typescript
// GOOD — role-based, survives CSS/layout changes
await page.getByRole('button', { name: 'Sign in' }).click();
await page.getByLabel('Email').fill(email);

// GOOD — data-testid for complex components without good semantics
page.locator('[data-testid="kpi-card"]:has-text("Total Deals")');

// GOOD — scoped to modal, reduces false positives
const modal = page.locator('div[role="dialog"]');
await modal.locator('button:has-text("Save")').first().click();

// ACCEPTABLE — has-text for table rows (Kadenwood pattern)
page.locator(`tr:has-text("${entityName}")`).first()

// AVOID — CSS class selectors break on any Tailwind refactor
page.locator('.modal-save-btn')
```

**Chained scoping** prevents cross-component conflicts:

```typescript
// Scoped: only finds "Save" inside the modal
this.modal.locator('button:has-text("Save")').first()

// Unscoped: might hit a "Save" button elsewhere on the page
page.locator('button:has-text("Save")').first()
```

---

## Test Data Management

**Pattern**: Create via Supabase client directly (fast), clean up with `E2E_TEST_` prefix.

```typescript
// e2e/fixtures/entity-factory.ts
const TEST_PREFIX = 'E2E_TEST_';

export const generateUniqueName = (entity: string) =>
  `${TEST_PREFIX}${entity}_${Date.now()}`;

// Create in Supabase directly — no UI interaction needed
export async function createCompany(data: Partial<TestCompany> = {}) {
  const { data: created, error } = await supabase
    .from('companies')
    .insert({ name: data.name || generateUniqueName('Company'), ...data })
    .select()
    .single();
  if (error) throw error;
  return created;
}

// Cleanup: delete everything with prefix across all tables
export async function cleanupAllTestData() {
  for (const table of ['tasks', 'deals', 'opportunities', 'contacts', ...]) {
    await supabase.from(table).delete().like('name', `${TEST_PREFIX}%`);
  }
}
```

**Service role bypass for RLS**: when RLS blocks anon deletes, use service role directly:

```typescript
// e2e/fixtures/service-role-admin.ts
export async function deleteEntityViaServiceRole(table: string, id: string) {
  const params = new URLSearchParams({ id: `eq.${id}` });
  const response = await serviceRoleFetch(`/rest/v1/${table}?${params}`, { method: 'DELETE' });
  return Boolean(response?.ok);
}
```

See the **supabase** skill for RLS and service role details.

---

## Auth State Persistence

Auth is handled once in a `setup` project dependency — all tests reuse stored cookies.

```typescript
// e2e/auth.setup.ts
setup('authenticate', async ({ page }) => {
  await page.goto('/login');
  await page.getByLabel('Email').fill(email);
  await page.getByLabel('Password').fill(password);
  await page.getByRole('button', { name: 'Sign in' }).click();
  await page.waitForURL('**/pipeline', { timeout: 20000 });
  await page.context().storageState({ path: 'e2e/.auth/user.json' });
});
```

```typescript
// playwright.config.ts — other projects depend on setup
{
  name: 'chromium',
  use: { storageState: 'e2e/.auth/user.json' },
  dependencies: ['setup'],
}
```

**NEVER** put login logic inside individual test files. Every test gets auth for free.

---

## Network Interception (Python)

Capture API responses without scraping the DOM — more reliable and faster.

```python
# apps/lead-scraper/fiddler_workflow/playwright_apollo_capture.py
captured_responses = []

async def handle_response(response):
    if '/api/v1/mixed_people/search' in response.url and response.status == 200:
        try:
            body = await response.json()
            if 'people' in body and body['people']:
                captured_responses.append(body)
        except Exception:
            pass  # malformed response — safe to skip

page.on('response', handle_response)
await page.goto(search_url, wait_until='domcontentloaded')
```

Use `wait_until='domcontentloaded'` instead of `'load'` for SPAs — `'load'` waits for all resources including images and fires too late.

---

## WARNING: Hard-coded `asyncio.sleep` Anti-Pattern

### The Problem:

```python
# BAD — arbitrary sleep, breaks under load or flakes on fast machines
await asyncio.sleep(8)  # "wait for login..."
await asyncio.sleep(5)  # "wait for page to load..."
```

**Why This Breaks:**
1. Slow CI environments need longer waits; fast dev machines waste time
2. Race conditions: the thing you're waiting for may not be done, or already done
3. Cascades: 10 sleeps × 5 seconds = 50s minimum even if the page loads in 1s

**The Fix:**

```python
# GOOD — wait for actual network condition or selector
await page.wait_for_load_state('networkidle')
await page.wait_for_selector('[data-loaded="true"]', timeout=15000)
await page.wait_for_url('**/dashboard**', timeout=20000)
```

The existing Apollo scraper uses `asyncio.sleep` throughout — acceptable for a one-off scraping script, but NEVER copy this pattern into production E2E tests.

---

## WARNING: `waitForTimeout` in Tests

```typescript
// BAD — flaky, environment-dependent
await page.waitForTimeout(1000);

// GOOD — wait for actual state change
await expect(page.locator('div[role="dialog"]')).toBeVisible({ timeout: 5000 });
await page.waitForLoadState('networkidle');
```

`waitForTimeout` in the codebase (e.g., `page-objects.ts`) is legacy — it works but adds latency. Prefer explicit expectations.

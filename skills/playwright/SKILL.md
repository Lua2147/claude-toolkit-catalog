All three files created. Here's what was generated:

---

**`playwright/SKILL.md`** — Quick overview covering the 3 usage modes in this codebase: TypeScript E2E testing (Kadenwood), Python async scraping (lead-scraper), and MCP live browser control. Includes run commands, key concept table, and related skills.

**`playwright/references/patterns.md`** — Deep patterns reference:
- Page Object Model exactly as used in `e2e/fixtures/page-objects.ts`
- Locator strategy hierarchy (role-based → data-testid → has-text)
- Test data management via entity factory + `E2E_TEST_` prefix
- Auth state persistence via `storageState`
- Python network interception pattern from the Apollo scraper
- WARNING: `asyncio.sleep` anti-pattern with real consequences and fixes
- WARNING: `waitForTimeout` in tests

**`playwright/references/workflows.md`** — Step-by-step workflows:
- New E2E test checklist (copyable)
- Python scraper template (network interception pattern)
- MCP live automation workflow (the `mcp__playwright__*` tools, including the HeyReach campaign creation use case)
- Multi-browser config with M1/x64 headless shell detection explained
- CI vs local settings table
- Debugging failures with common symptom→cause→fix table
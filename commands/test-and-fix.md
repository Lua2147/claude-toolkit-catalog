Run tests for the specified app and fix any failures.

1. Identify which app we're working in from context or ask
2. Look for test commands in that app's package.json, Makefile, or CLAUDE.md
3. Run the test suite
4. If tests fail: read the error output, fix the issues, re-run tests
5. Repeat until all tests pass
6. Summarize what was broken and what was fixed

Common test commands by app:
- email-verifier: `cd apps/email-verifier && python3 -m pytest tests/`
- kadenwood: `cd apps/kadenwood && npm run test`
- deal-origination: `cd apps/deal-origination && python3 -m pytest`
- General Python: `python3 -m pytest`
- General Node: `npm test`

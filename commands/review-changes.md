Review all uncommitted changes and provide a summary.

1. Run `git diff --stat` for unstaged changes
2. Run `git diff --cached --stat` for staged changes
3. Run `git diff` to see the actual changes
4. Provide a concise summary:
   - What files changed and why
   - Any potential issues (breaking changes, missing tests, security concerns)
   - Whether changes are ready to commit or need more work
5. Flag anything that looks wrong, incomplete, or risky

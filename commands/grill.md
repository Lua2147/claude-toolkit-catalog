Adversarial code review. Be harsh. Don't let me ship bad code.

1. Read all uncommitted changes with `git diff` and `git diff --cached`
2. Review for:
   - Logic errors and edge cases
   - Security vulnerabilities (injection, auth bypass, credential exposure)
   - Performance issues (N+1 queries, unnecessary loops, missing indexes)
   - Missing error handling at system boundaries
   - Breaking changes to existing APIs or interfaces
   - Race conditions in async code
3. For each issue found, explain:
   - What's wrong
   - What could go wrong in production
   - How to fix it
4. Give a verdict: SHIP IT or HOLD — with reasons
5. If HOLD, list the minimum fixes needed before shipping

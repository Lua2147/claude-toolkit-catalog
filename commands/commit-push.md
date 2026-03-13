Commit and push current changes following the session protocol.

1. Run `git status` to see what's changed
2. Run `git diff --cached --stat` and `git diff --stat` to understand the changes
3. Scan staged changes for secrets: grep for api_key, secret, password, token, credential, private_key — if found, STOP and warn
4. Stage relevant files (prefer specific files over `git add -A`)
5. Write a concise commit message focused on the "why" not the "what"
6. Commit with Co-Authored-By trailer
7. Push to origin
8. Run `git status` to confirm clean state

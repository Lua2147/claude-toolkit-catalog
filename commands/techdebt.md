End-of-session sweep for technical debt in the files touched this session.

1. Run `git diff --name-only HEAD~3` to find recently changed files (or use `git diff --name-only` for uncommitted)
2. For each changed file, check for:
   - Duplicated code that could be extracted
   - Dead code (unused imports, unreachable branches, commented-out blocks)
   - TODO/FIXME/HACK comments that should be resolved
   - Overly complex functions that should be split
   - Inconsistent naming or patterns vs. the rest of the codebase
3. For each finding: state the file, line, issue, and suggested fix
4. Only flag real issues — don't manufacture problems

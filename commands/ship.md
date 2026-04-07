Invoke the `ship-software` skill to start the software shipping SOP v3.0.

Begin by asking: "What are we building?" Then:

1. Determine the track (Hotfix / Small Build / Full Build) based on complexity
2. Run `/toolkit-scout` to check what already exists
3. Follow the SOP phase-by-phase as defined in the skill

Core philosophy: Define "done" explicitly (3-5 acceptance criteria), plan densely (dependency graph, parallel groups, worker assignments, worktrees), build fast in parallel, review at every phase, iterate from real usage.

Track 3 rules:
- All non-dependent tasks run in parallel
- Every task in its own worktree
- Orchestrator manages workers, reviews each wave before merging
- Review is continuous (every build wave), not a gate at the end
- `/review:plan` runs on every plan

$ARGUMENTS

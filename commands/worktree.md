Create or list git worktrees for parallel Claude sessions.

Usage: /worktree [create|list|remove] [name]

## Create
1. Create a new worktree: `git worktree add "../mp-wt-$name" main`
2. Confirm the path and tell the user to open a new terminal in that directory
3. Remind: each worktree is an isolated copy — changes won't conflict with other sessions

## List
1. Run `git worktree list` to show all active worktrees
2. Show which ones are in use

## Remove
1. Run `git worktree remove "../mp-wt-$name"`
2. Confirm removal

Worktrees live at the same level as the main repo (e.g., ~/mp-wt-1, ~/mp-wt-2).

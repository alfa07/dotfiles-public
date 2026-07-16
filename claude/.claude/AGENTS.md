## Code Style Guidelines
- do not add comments inside methods
- in commit messages use prefixes like feat(service): .. or fix(service): ... ref(service): ...

## Git worktree safety
- Inside an `ft` worktree, never run `git reset --hard main` or `git reset --hard origin/main` from a feature branch — `--hard` discards the feature branch's commits. To pick up new main commits, use `git merge origin/main` or `git rebase origin/main` instead.
- Prefer `origin/main` over local `main` when referencing the trunk; local `main` can be stale or moved by another process.
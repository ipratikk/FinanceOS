# Update PR

Syncs the current branch with main and pushes the update.

## Usage

```
/update-pr
```

## What This Does

1. If uncommitted changes exist → commit via `/commit` first
2. Fetch latest main:
   ```bash
   git fetch origin main
   ```
3. Check if branch is behind:
   ```bash
   git rev-list --count HEAD..origin/main
   ```
4. If behind → rebase:
   ```bash
   git pull --rebase origin main
   ```
5. Push:
   ```bash
   git push --force-with-lease
   ```
6. Confirm push succeeded and report the branch status

## Important Notes

- Uses `--force-with-lease` — aborts safely if the remote was updated by someone else
- If rebase has conflicts, stop and report them — do not auto-resolve
- If on `main`, prompt to switch to the correct branch before proceeding
- After pushing, CI will trigger automatically — run `/create-pr` when ready

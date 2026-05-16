---
name: commit
description: Create clean, architecture-grouped git commits from unstaged changes.
---

# /commit

**Default agent:** haiku (mechanical grouping) / sonnet (mixed-layer calls)
**Script:** `.claude/scripts/session/commit.sh`

## Usage

- `/commit` → auto-group by layer, commit each group via caveman-commit
- `/commit --dry-run` → show groups without committing

## Grouping layers (in order)

1. `Packages/FinanceParsers` — parsers
2. `Packages/FinanceCore` — finance-core
3. `Packages/FinanceUI` — finance-ui
4. `FinanceOS/` — app
5. `.claude/` — claude-config
6. `Scripts/` — scripts
7. `Tests/` — tests
8. catch-all — misc

## Safety rules

- confirm before committing if changes appear destructive
- never commit `.env`, generated files, debug prints
- call out suspicious changes before staging

## After commits

Return: list of created commits only. No essays.

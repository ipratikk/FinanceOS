---
name: commit
description: Create clean, architecture-grouped git commits using caveman:caveman-commit for deterministic message generation. Layer: parsers, finance-core, finance-ui, app, claude-config, scripts, tests, misc.
---

# /commit

Groups unstaged changes by architecture layer. For each group, invokes `caveman:caveman-commit` for ultra-compressed Conventional Commits messages.

**Default agent:** haiku (mechanical grouping) / sonnet (mixed-layer calls)

## Workflow

1. Collect modified files (unstaged + staged)
2. Group by layer (see below)
3. For each group:
   - Stage files
   - **Invoke caveman:caveman-commit** to generate message
   - Create commit

## Usage

- `/commit` → auto-group by layer, commit each group (requires caveman:caveman-commit)
- `/commit --dry-run` → show groups without committing

## Grouping layers (in order)

1. `Packages/FinanceCore` — finance-core
2. `Packages/FinanceUI` — finance-ui
3. `FinanceOS/` — app
4. `.claude/` — claude-config
5. `Scripts/` — scripts
6. `Tests/` — tests
7. catch-all — misc

## Safety rules

- confirm before committing if changes appear destructive
- never commit `.env`, generated files, debug prints
- call out suspicious changes before staging

## After commits

Return: list of created commits only. No essays.

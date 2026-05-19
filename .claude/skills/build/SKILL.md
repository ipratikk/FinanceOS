---
name: build
description: Run swift / xcodebuild for FinanceOS with minimal output. Default agent haiku. Escalates only when fix requires real reasoning.
---

# /build

**Default agent:** haiku
**Script:** `.claude/scripts/build/build.sh`

## Variants

- `/build` → `build.sh mac`
- `/build ios` → `build.sh ios`
- `/build core` → `build.sh core`
- `/build parsers` → `build.sh parsers`
- `/build test` → `build.sh test`
- `/build clean` → `build.sh clean`
- `/build all` → `build.sh all`

## Output contract

Success: `Build complete (<target>, <Xs>)`
Failure: `file:line: error: <message>` only.

## Escalation triggers

- `Cannot conform to Sendable` / `actor-isolated` → opus
- `Cannot find type X` for a NEW symbol haiku doesn't know → sonnet
- linker errors across 2+ targets → sonnet
- 3+ retry loops without progress → sonnet

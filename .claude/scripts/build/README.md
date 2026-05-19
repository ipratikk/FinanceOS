# scripts/build/

Build scripts for FinanceOS Swift packages and Xcode workspace.

## Scripts

- `build.sh [target]` — build one target or all. Targets: `core`, `parsers`, `mac`, `ios`, `test`, `clean`.
  Filters output to errors/warnings only. Exit 1 on failure.

## Output contract

Success: `Build complete (<target>, <Xs>)`
Failure: `file:line: error: <message>` — no commentary.

## Escalation (exit codes)

- 0 = clean build
- 1 = compile errors (haiku handles)
- 2 = linker / cross-target errors (escalate to sonnet)

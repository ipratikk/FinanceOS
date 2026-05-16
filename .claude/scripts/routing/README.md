# scripts/routing/

Deterministic agent routing logic.

## Scripts

- `route.sh <prompt>` — print agent decision (haiku|sonnet|opus) + reason. Exit 0 always.
- `simulate.sh` — run all canned test cases, exit 1 on any failure or opus leak.
- `lib.sh` — shared `route_prompt()` function, sourced by route.sh + simulate.sh.

## Output contract

`route.sh` prints two lines:
```
AGENT=<haiku|sonnet|opus>
REASON=<text>
```

`simulate.sh` prints pass/fail table, exits 1 on failure.

## Source of truth

Routing rules live in `lib.sh`. The hooks/routing-lib.sh symlinks here.

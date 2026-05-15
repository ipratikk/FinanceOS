---
name: build
description: Run swift / xcodebuild for FinanceOS with minimal output. Default agent haiku. Escalates only when fix requires real reasoning.
---

# /build

Fast compile loop. Haiku-driven.

## Variants

- `/build` → macOS app (default)
- `/build ios` → iOS scheme
- `/build core` → FinanceCore Swift package
- `/build parsers` → FinanceParsers Swift package
- `/build clean` → clean derived data + rebuild
- `/build test` → tests

## Default agent

**haiku-agent**. Builds are mechanical. Errors that are pure-syntax stay in haiku.

## Escalation triggers

If the build fails with:
- "Cannot find type X in scope" and X is a public symbol → likely module import bug → haiku fixes
- "Cannot conform to Sendable" / "actor-isolated" → escalate to **opus-agent**
- "Cannot find type X" where X is a NEW symbol haiku doesn't know about → escalate to **sonnet-agent**
- linker errors across 2+ targets → escalate to **sonnet-agent**
- More than 3 retry loops without progress → escalate to **sonnet-agent**

## Execution

```bash
swift build -c release --package-path Packages/FinanceCore 2>&1 | tail -40
swift build -c release --package-path Packages/FinanceParsers 2>&1 | tail -40
xcodebuild -workspace FinanceOS.xcworkspace -scheme FinanceOSMac -configuration Debug -quiet 2>&1 | grep -E "error:|warning:|BUILD"
```

## Output contract

Build success: one line `Build complete (Xs)`.
Build fail: file:line + error message only. No commentary.

## Token rules

- never paste full xcodebuild output
- always `2>&1 | tail -N` or grep-filter
- on failure: read ONLY the failing file's failing region

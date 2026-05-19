---
description: Print the routing decision for a task — which agent should handle it and why. Read-only meta-command.
allowed-tools: Read
argument-hint: <task description>
---

# /route

Diagnostic: ask the routing layer "which agent for THIS task?" without executing it.

## Use

```
/route "fix typo in HDFCPDFParser comment"
→ haiku

/route "rewrite the dedup engine to handle currency conversion"
→ opus  (cross-module + heuristic design)

/route "add a new SwiftUI screen for transaction tags"
→ sonnet

/route "rebuild swift package"
→ haiku
```

## Decision rules (in order)

1. Keywords "architecture / design / pipeline / heuristic / concurrency / sendable / migration" → **opus**
2. Keywords "feature / view / viewmodel / screen / test for / wire / integrate" → **sonnet**
3. Keywords "build / lint / format / rename / commit / push / run / generate / regenerate / search / grep / find / typo" → **haiku**
4. File scope > 5 unrelated files → **opus**
5. File scope 2-5 files in one module → **sonnet**
6. File scope 1-2 files → **haiku**
7. Parser-related AND root cause unknown → **opus**
8. Parser-related AND fix is mechanical (date format, etc.) → **haiku**
9. SwiftUI work (single feature scope) → **sonnet**
10. Anything ambiguous → **sonnet** (NEVER default to opus)

## Output

```
Task: <task description>
Agent: <haiku|sonnet|opus>
Reason: <one line>
Estimated cost tier: <1=cheap, 2=mid, 3=expensive>
```

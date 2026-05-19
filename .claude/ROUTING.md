# FinanceOS Multi-Agent Routing

Goal: aggressively minimize Opus usage. Opus is the most expensive model — treat it like a senior architect's calendar, not a hammer.

## Model strategy

| Model  | Role | Use it for | Cost tier |
|--------|------|------------|-----------|
| Haiku  | Executor | Builds, lints, formatting, git, file ops, repetitive edits, search/grep, fixture regen, test runs, snapshot updates, mechanical refactors | 1 (cheap) |
| Sonnet | Implementer | SwiftUI features, ViewModels, parser cleanup, test writing, medium refactors, integration | 2 (mid) |
| Opus   | Architect | Pipeline design, heuristic design, concurrency reasoning, cross-module refactor, DB schema, hard edge cases, recursive debug | 3 (expensive) |

## Default routing (in order — first match wins)

1. **Keyword: architecture / pipeline / heuristic / concurrency / sendable / migration design** → **opus**
2. **Keyword: feature / view / viewmodel / screen / integrate / wire / write tests for** → **sonnet**
3. **Keyword: build / lint / format / rename / commit / push / run / regenerate / search / typo / fix typo / snapshot** → **haiku**
4. **File scope > 5 unrelated files** → **opus** (planning) → **haiku** (execution)
5. **File scope 2-5 files in one module** → **sonnet**
6. **File scope 1-2 files** → **haiku**
7. **Parser failure with unknown root cause** → **opus** (max 3 probe rounds)
8. **Parser failure with mechanical fix (date format, regex tweak)** → **haiku**
9. **Ambiguous** → **sonnet** (NEVER default to opus)

## Preferred workflow

```
opus  (plans, 1 invocation)
  ↓
haiku (executes, N invocations)
  ↓
sonnet (refines integration if needed, optional)
```

## Hard rules

### Opus must NOT
- run builds repeatedly
- do formatting / linting
- perform repetitive edits
- handle boilerplate
- execute mechanical refactors
- run test loops
- update fixtures / snapshots
- commit code
- read more than 5 files before producing a plan

### Haiku must NOT
- design heuristics
- introduce new abstractions
- decide architecture
- proceed when "how" is unclear (escalate instead)
- edit 3+ unrelated files

### Sonnet must NOT
- redesign pipelines
- change module boundaries
- invent new architectural layers
- handle cross-module refactor without an opus plan

## Recursive parser refinement flow

```
1. user runs /parser-refine <pdf>
2. haiku runs CLI + compare → records baseline
3. opus reads MAX 2 sample diffs → proposes ONE heuristic change (< 30-line diff)
4. haiku applies diff + rebuilds + reruns
5. accuracy improved? → repeat (max 5 cycles)
                else? → revert + STOP
6. final report written to parser_refine_log.md
```

Opus is capped at 5 invocations per refinement loop. Hard limit.

## Cost guards

- `escalation-detector.sh` hook annotates each user prompt with a routing hint
- `summarize-failure.sh` hook collapses verbose build/test output into one line
- `post-parser-edit.sh` hook auto-detects parser regressions cheaply (haiku-level)
- All hooks are read-only ANNOTATIONS — they don't block actions, just inform the agent

## When in doubt

Downgrade. Opus must justify its existence — every other model is the default.

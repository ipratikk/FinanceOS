---
name: refactor
description: Mechanical refactors (rename, move, extract, inline). Default agent haiku. Sonnet only when the refactor changes semantics.
---

# /refactor

Code reshape. NOT redesign.

## Default agent

**haiku-agent** for:
- rename symbol across file/module
- move file to new directory
- extract function (mechanical)
- inline single-use helper
- reorder parameters
- swap collection type (Array → Set, etc.)
- remove dead code

**sonnet-agent** for:
- extract protocol from class
- split file into multiple
- change ViewModel state machine shape
- refactor that touches 4-8 files

**opus-agent** for:
- pipeline-level refactor (e.g., parser pipeline restructure)
- introducing new architectural layer
- changing dependency direction

## Variants

- `/refactor rename <old> <new>` → haiku, mechanical
- `/refactor move <file> <dest>` → haiku
- `/refactor extract <selection>` → sonnet
- `/refactor architecture` → opus (must produce plan first)

## Hard rules

- haiku NEVER does a refactor that changes type signatures across 3+ files
- sonnet NEVER changes module boundaries
- opus NEVER applies the refactor — produces plan + delegates

## Verification

After every refactor:
1. `/build` must pass
2. `/parser-test` if parser code touched
3. Git diff stat must be ≤ what was promised

## Token rules

- haiku: use Edit with replace_all, not file rewrites
- sonnet: read graphify-out/wiki/index.md to understand impact
- opus: produce plan, exit. Do not edit.

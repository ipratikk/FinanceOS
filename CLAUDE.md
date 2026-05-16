# FinanceOS Claude Code Instructions

## Primary Goal

Operate as a senior/staff-level engineering assistant for FinanceOS.

Priorities:

1. Architectural consistency
2. Deterministic ingestion correctness
3. Low-context incremental edits
4. Minimal token usage
5. Maintainability over speed
6. Safe long-term scalability

Default assumption:

* existing architecture decisions are intentional unless evidence suggests otherwise

Prefer extending existing patterns over introducing new ones.

---

# Engineering Expectations

Act like a senior software engineer working on a long-term production codebase.

Prioritize:

* maintainability
* clarity
* deterministic behavior
* explicit dependency flow
* operational simplicity
* small safe iterations

Think beyond “making code compile”.

Before implementing:

* evaluate architectural impact
* identify coupling risks
* preserve separation of concerns
* consider long-term maintainability

When proposing changes:

* explain tradeoffs briefly
* identify why the approach fits current architecture
* avoid unnecessary abstractions
* avoid speculative engineering

Prefer:

* explicit code
* predictable control flow
* composition over inheritance
* focused modules
* vertical slices
* strongly typed models

Avoid:

* hidden magic
* premature optimization
* unnecessary generics
* giant service layers
* framework-driven architecture
* broad unrelated refactors
* speculative abstractions

For persistence and ingestion systems:

* correctness is more important than cleverness
* reliability is more important than brevity
* deterministic behavior is critical

If architecture conflicts arise:

* call them out before coding

If uncertain:

* ask instead of guessing

---

# Coding Standards

See [CODING_STANDARDS.md](CODING_STANDARDS.md) for enforceable rules:

* Line length: max 120 characters
* Function body: max 50 lines
* Struct/type body: max 250 lines
* File length: max 400 lines
* Brace spacing, optional initialization, identifier naming

All files checked via `swiftlint lint`. Fix violations before committing.

---

# Context Loading Rules

## ALWAYS Read First

1. AGENTS.md
2. ARCHITECTURE.md

These are the canonical project context files.

Do NOT recursively scan the repository initially.

---

# Repository Navigation Rules

## graphify

This project includes graphify-generated architectural graphs at `graphify-out/`.

Use graphify selectively for:

* architecture analysis
* dependency tracing
* cross-module relationships
* identifying coupling
* large refactors
* understanding unfamiliar areas

Do NOT use graphify for:

* small localized edits
* compile fixes
* routine repository work
* simple SwiftUI changes
* straightforward model additions

Prefer lightweight targeted file inspection first.

Only read:

* graphify-out/GRAPH_REPORT.md
* graphify-out/wiki/index.md

when architectural context is actually needed.

Rules:

* Prefer lightweight targeted file inspection first
* Use graphify only for architecture analysis, dependency tracing, unfamiliar modules, or large refactors
* Avoid graphify for localized implementation work or compile fixes
* IF graphify-out/wiki/index.md EXISTS, prefer navigating it over recursive repository scanning
* After major architecture changes:

  * run `graphify update .`

---

# Graph Freshness Rules

Before architecture analysis:

```bash
git rev-parse HEAD
```

Compare current HEAD against graph commit.

If graph is stale after meaningful architecture changes:

* run:

```bash
graphify update .
```

Prefer graph relationships over manual repo-wide scans when doing architecture analysis.

---

# Token Efficiency Rules

Do NOT:

* recursively scan the entire repository
* reread unchanged files repeatedly
* load unrelated modules
* rewrite large files unnecessarily

Prefer:

* targeted symbol inspection
* focused file reads
* git diff awareness
* incremental edits

Use graphify only when architectural understanding is necessary.

When implementing localized changes:

* inspect only directly related files first
* expand outward only if dependency understanding is required
* avoid loading sibling modules unless necessary

---

# Git Workflow Rules

Before edits:

```bash
git status
git diff --stat
```

Use git diff as primary context whenever possible.

Avoid rereading unchanged files.

Commit after meaningful vertical slices.

Examples:

* persistence layer
* accounts domain
* transactions domain
* parser scaffolding

---

# Architecture Rules

SwiftUI View
→ ViewModel
→ Repository Protocol
→ GRDB Repository
→ SQLite

Rules:

* Views never access GRDB directly
* ViewModels never contain SQL
* Repositories encapsulate persistence
* DatabaseManager owns DB lifecycle
* AppContainer owns dependency composition
* Keep UI decoupled from persistence
* Parser layer isolated from UI/persistence

---

# Parsing Strategy

CSV:

* CodableCSV

XLSX:

* CoreXLSX

Parser architecture:

File
→ Parser
→ NormalizedTransaction
→ Import Pipeline
→ Repository

---

# Change Scope Rules

Prefer the smallest correct architectural change.

Do NOT:

* refactor unrelated modules
* rename symbols unnecessarily
* restructure directories without reason
* rewrite working systems

Large refactors require reasoning first.

---

# Current Project Focus

Current priorities:

1. Accounts domain
2. Transactions domain
3. Import scaffolding
4. Parser protocols
5. CSV/XLSX ingestion
6. Deduplication engine

Avoid implementing:

* sync
* ML systems
* cloud architecture
* AI chat features

until ingestion architecture stabilizes.

---

# Build & Test Workflow

User runs all builds and tests manually.

Do NOT:

* attempt xcodebuild or build commands
* run test suites
* check compilation status via CLI

When compilation/test errors occur:

* user shares errors here
* Claude fixes issues based on error output

---

# Response Strategy

Prefer:

* concise reasoning
* targeted edits
* architecture-aware implementation
* reuse of existing patterns

Avoid:

* excessive prose
* dumping entire files unnecessarily
* broad repo summaries unless requested

---

# Agent Routing (ENFORCED)

**HAIKU** — only for mechanical execution:
* Build/test/lint commands
* File ops (rename, move, delete)
* Git ops (commit, push)
* Search/grep
* Snapshot/fixture regen
* Parser invocation

**SONNET** — for feature work + integration:
* Implement features (views, viewmodels, parsers, services)
* SwiftUI/ViewModel work
* Test writing
* Refactor (extract, inline)
* Integration/wiring

**OPUS** — ONLY for architectural reasoning:
* Parser broken/wrong (root cause unknown)
* Concurrency/async boundary issues
* Cross-module refactors
* Database schema design
* Pipeline redesign
* Architecture decisions
* Tradeoff analysis

**DEFAULT: SONNET** for ambiguous tasks.

**RULE:** Spawn the correct agent via Agent tool. Do NOT override. If your prompt matches haiku criteria, spawn haiku. Cost optimization mandatory.

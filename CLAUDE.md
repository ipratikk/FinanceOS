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

# Quick Start

```bash
bash bootstrap.sh   # install tools, global skills, seed log dirs (run once after cloning)
```

Key skills: `/build` `/lint` `/parser-test` `/commit` `/review` `/refactor`

Key make targets: `make parser-test`, `make parser-parse FILE=<path>`, `make parser-build`

---

# Engineering Expectations

Act like a senior software engineer on a long-term production codebase.

* Prefer explicit, predictable code over clever abstractions
* Evaluate architectural impact and coupling risks before implementing
* Explain tradeoffs briefly; identify why an approach fits the current architecture
* For persistence/ingestion: correctness > cleverness, determinism is critical
* Call out architecture conflicts before coding; ask when uncertain

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

## Packages

| Package | Owns |
|---------|------|
| FinanceCore | Models, Repositories (GRDB), DatabaseManager, AppContainer, Logging |
| FinanceParsers | Parser protocols, bank-specific parsers, import pipeline, deduplicator |
| FinanceUI | SwiftUI components, design system (FDS) |
| FinanceTesting | Shared test helpers, fixtures, golden JSON |

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

Phases 1–10 complete (Ledger unification, import pipeline, dedup engine, UI migration).

## Active: MVVM Refactoring (Phases 1–7)

**All 7 phases complete. MVVM refactoring done.**

Full plan: `docs/MVVM_REFACTORING_PLAN.md`
Architecture standards being enforced: `docs/ARCHITECTURE.md` (Presentation Layer section)

### Phase Tracker

| Phase | Title | Status |
|-------|-------|--------|
| **1** | Missing ViewModels | ✅ done |
| 2 | Fix Transactions Split State | ✅ done |
| 3 | Dashboard Cleanup | ✅ done |
| 4 | Remove Repository Access from Views | ✅ done |
| 5 | Service Layer Extraction | ✅ done |
| 6 | Pre-format All Display Strings | ✅ done |
| 7 | Protocol Abstractions + Misc Cleanup | ✅ done |

### Session Protocol (ENFORCED)

When user says **"continue Phase N"** or **"start Phase N"**:

1. Read `docs/MVVM_REFACTORING_PLAN.md` for that phase's spec
2. Read `docs/ARCHITECTURE.md` (Presentation Layer section) for enforced rules
3. Implement the phase in a worktree branch
4. Run lint and build before creating PR
5. Create PR via `/create-pr`
6. Update phase status in `docs/MVVM_REFACTORING_PLAN.md` (→ ✅, add PR link)
7. **STOP — do not advance to next phase**
8. Tell user: "Phase N complete. PR created. Start next session to continue Phase N+1."

**One phase = one PR. Never implement multiple phases in one session.**

## Parser / ingestion priorities (parallel track)

1. CSV/XLSX parser hardening (ICICI, HDFC, Axis, and other Indian banks)
2. Statement format auto-detection
3. Bank-specific parsing rules
4. Duplicate detection at scale
5. Analytics and spending insights

Avoid implementing:

* sync
* ML systems
* cloud architecture
* AI chat features

---

# Build & Test Workflow

Use project skills — do not invoke build tools directly unless a skill isn't available.

| Task | Skill | Make target |
|------|-------|-------------|
| Build | `/build` | `make parser-build` |
| Test parsers | `/parser-test` | `make parser-test` |
| Parse a file | — | `make parser-parse FILE=<path>` |
| Lint | `/lint` | — |
| Commit | `/commit` | — |

Post-edit hooks automatically lint and incrementally build affected packages after every Swift file edit.

When build/test errors occur, share the output — Claude fixes based on error text.

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

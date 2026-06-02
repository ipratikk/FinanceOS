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

Default: existing architecture decisions are intentional unless evidence suggests otherwise. Extend existing patterns over introducing new ones.

---

# Quick Start

```bash
bash bootstrap.sh   # install tools, global skills, seed log dirs (run once after cloning)
```

Key skills: `/build` `/lint` `/parser-test` `/commit` `/review` `/refactor`

Key make targets: `make parser-test`, `make parser-parse FILE=<path>`, `make parser-build`

---

# Engineering Expectations

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

**ALWAYS read first:**

1. `AGENTS.md`
2. `ARCHITECTURE.md`

These are the canonical project context files. Do NOT recursively scan the repository initially.

---

# graphify

Architectural graphs at `graphify-out/`. Use selectively:

**Use for:** architecture analysis, dependency tracing, cross-module relationships, identifying coupling, large refactors, understanding unfamiliar areas.

**Skip for:** localized edits, compile fixes, routine work, simple SwiftUI changes.

After major architecture changes, run `graphify update .`.

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
* `git diff` as primary context
* incremental edits

When implementing localized changes: inspect only directly related files first; expand outward only if dependency understanding is required.

---

# Architecture Rules

```
SwiftUI View → ViewModel → Repository Protocol → GRDB Repository → SQLite
```

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
| FinanceIntelligence | Transaction intelligence, behavior analysis (salary/routines/cashflow), categorization pipeline |

---

# Parsing Strategy

CSV → CodableCSV. XLSX → CoreXLSX.

```
File → Parser → NormalizedTransaction → Import Pipeline → Repository
```

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

Phases 1–10 complete (Ledger unification, import pipeline, dedup engine, UI migration, MVVM refactor).

## Active: Financial Intelligence Platform

Primary goal: Build intelligent transaction analysis, behavior detection, and spending insights.

### Core Work (FinanceIntelligence)

1. Transaction categorization & intelligence service
2. Behavior analysis: salary detection, financial routine detection, cashflow analysis
3. Post-processing pipeline (merchant deduplication, narration enrichment)
4. Spending insights, patterns, and analytics
5. CLI tools for batch intelligence processing

### Enabler: Parser / Ingestion

Parser hardening (CSV/XLSX, Indian banks, dedup, format detection) supports intelligence ingestion.

---

Avoid implementing: sync, pure ML training, cloud architecture, AI chat features.

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

---

# Git & PR Workflow

## Branch Strategy

**ALWAYS** create a fresh branch from latest `origin/main` before starting work on a new ticket, feature, or issue:

```bash
git fetch origin main
git checkout -b <type>/<description>(<jira-key>) origin/main
```

Branch naming: `feat/description(FINOS-5)`, `fix/bug-title(KAN-42)`, `docs/update(PORTAL-8)`

**Why:** Ensures:
- Clean, isolated commits for each JIRA ticket
- No merge conflicts from prior work on same branch
- Each PR focuses on one ticket/feature
- Easier code review and git history

## PR Creation

**ALWAYS** use `/create-pr` skill to create pull requests. Do NOT use `gh pr create` directly.

`/create-pr` runs the full validation pipeline:
- Phase 0: Branch naming validation
- Phase 1: Changed file detection
- Phase 2: SwiftLint (no violations allowed)
- Phase 3: Package tests (all affected packages must pass)
- Phase 4: macOS build (must succeed)
- Phase 5: Branch sync and push
- Phase 6: PR creation with proper template

Only override with `--skipValidation` when:
- Pre-existing test failures confirmed on `origin/main`
- Changes are Python-only (no Swift code impact)
- Explicitly documented in commit message

Proper PR workflow ensures:
- No broken builds are pushed
- Test failures are caught before review
- Consistent PR template with JIRA/GitHub issue linking
- Automatic JIRA workflow transitions

---

# Agent Routing (ENFORCED)

**HAIKU** — mechanical execution only: build/test/lint, file ops, git ops, search/grep, snapshot regen, parser invocation.

**SONNET** — feature work + integration: views, viewmodels, parsers, services, SwiftUI, test writing, refactors.

**OPUS** — ONLY for: parser root-cause unknown, concurrency/async boundaries, cross-module refactors, DB schema design, pipeline redesign, architecture decisions.

**DEFAULT: SONNET.** Spawn correct agent via Agent tool — cost optimization mandatory.

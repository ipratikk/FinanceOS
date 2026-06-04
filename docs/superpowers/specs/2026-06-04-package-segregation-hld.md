# FinanceOS Package Segregation — HLD

**Author:** Pratik Goel  
**Date:** 2026-06-04  
**Status:** Approved  
**Type:** High-Level Design  
**Related:** [PRD](2026-06-04-package-segregation-prd.md) · [LLD](2026-06-04-package-segregation-lld.md)

---

## Table of Contents

1. [Current Architecture — Violations](#1-current-architecture--violations)
2. [Target Architecture](#2-target-architecture)
   - 2.1 Dependency Graph
   - 2.2 Package Responsibilities
3. [Key Design Decisions](#3-key-design-decisions)
4. [Adaptive Token System Overview](#4-adaptive-token-system-overview)
5. [Cross-Cutting Invariants](#5-cross-cutting-invariants)
6. [Phasing Strategy](#6-phasing-strategy)
7. [Risk Assessment](#7-risk-assessment)

---

## 1. Current Architecture — Violations

### Dependency Graph (current, with violations)

```
FinanceParsers ──────────────────────────────────────┐
                                                      ▼
FinanceCore ──(+ SwiftUI contamination!)──────────────┤
  ❌ Design/ folder: 8 files import SwiftUI            │
  ❌ Bank.swift: tintColor: Color (SwiftUI)            │
  ❌ TargetCreationState: UI state in core model       │
  ❌ SwiftCSV: stale dep (used only by FinanceParsers) │
                                                      │
FinanceUI ──(depends on FinanceCore)                  │
                                                      │
FinanceIntelligence ──(+ SwiftUI contamination!)──────┤
  ❌ EnvironmentKey.swift: import SwiftUI             │
  ❌ FinanceTesting in production target              │
  ❌ GRDB: direct dep, duplicates FinanceCore's layer │
  ❌ No typed request/response API                   │
                                                      │
FinanceOSMac ──(app target)                           │
  depends on: FinanceCore, FinanceIntelligence        │
  (FinanceUI implicit via Xcode workspace)            │
                                                      │
No FinanceCLI exists ────────────────────────────────┘
```

### Violations by Package

| Package | Violation | Severity |
|---------|-----------|----------|
| FinanceCore | `Design/` folder (8 files) import `SwiftUI` | Critical |
| FinanceCore | `Bank.swift`: `tintColor: Color` (SwiftUI type in domain model) | High |
| FinanceCore | `TargetCreationState`: UI state with "Lives in ViewModel" comment | High |
| FinanceCore | `SwiftCSV` stale Package.swift dependency | Low |
| FinanceIntelligence | `EnvironmentKey.swift` imports `SwiftUI` | Critical |
| FinanceIntelligence | `FinanceTesting` in production target | High |
| FinanceIntelligence | Direct `GRDB` dependency + parallel persistence layer | Medium |
| FinanceIntelligence | No typed API — internal types exposed | Medium |
| (Missing) | No unified `FinanceCLI` package | High |
| AppColors | All `Text.*`, `Fill.*`, `Glass.*`, `Border.*` dark-mode only | High |
| AppTypography | Fixed font sizes — no display-size adaptation | Medium |

---

## 2. Target Architecture

### 2.1 Dependency Graph (target)

```
FinanceParsers
    │  owns: parser protocol, bank parsers, format detection
    │  no deps
    │
    ▼
FinanceCore ──────────────────────────────────────────────────────────┐
    │  owns: models, repos (protocol + GRDB impl), DatabaseManager,   │
    │         AppContainer, import pipeline, spending service, logging  │
    │  no: SwiftUI                                                      │
    │  deps: FinanceParsers, GRDB                                       │
    │                                                                   │
    ├───────────────────────────────────────────────┐                  │
    │                                               │                  │
    ▼                                               ▼                  │
FinanceUI                               FinanceIntelligence            │
    │  owns: FDS tokens (adaptive,           owns: categorization,     │
    │         light/dark, scaled),                  behavior analysis, │
    │         FDS components, modifiers,            ML infra,          │
    │         SwiftUI extensions on core            typed API          │
    │         types                                 (request/response) │
    │  no: ViewModels, GRDB, navigation      no: SwiftUI               │
    │  deps: FinanceCore                     deps: FinanceCore, GRDB,  │
    │                                              swift-transformers, │
    │                                              ZIPFoundation, MLX  │
    │                                               │
    └──────────────────┬────────────────────────────┘
                       │
                       ▼
                FinanceOSMac (App)
                    owns: Views, ViewModels, navigation,
                           EnvironmentKey definitions,
                           TargetCreationState,
                           CategorizationScheduler,
                           app entry point + Scene config
                    deps: FinanceCore, FinanceUI, FinanceIntelligence

FinanceCLI (new) ─── FinanceCore + FinanceParsers + FinanceIntelligence
    owns: parse / import / analyze / pipeline commands
    no: SwiftUI
    deps: FinanceCore, FinanceParsers, FinanceIntelligence, ArgumentParser

FinanceTesting ─── FinanceCore + FinanceParsers
    rule: testTarget(…) only — never production target
```

### 2.2 Package Responsibilities (detailed)

#### FinanceParsers
| | |
|-|-|
| **Public API** | `StatementParser` protocol, `InstitutionStatementParser`, `StatementParserRegistry`, `NormalizedTransaction`, `ParsedStatement`, `StatementSource`, `StatementSourceType`, `TransactionImportError` |
| **Executables** | `FinanceParserCLI` (parse-only, JSON output) |
| **Key invariant** | Zero deps — can be linked to any target on any platform |

#### FinanceCore
| | |
|-|-|
| **Domain models** | `Transaction`, `Ledger`, `Bank`, `Banks`, `CardMetadata`, `CardNetwork`, `LedgerKind`, `EnrichmentProvenance` |
| **Repository protocols** | `TransactionRepository`, `LedgerRepository`, `BankRepository` |
| **Repository implementations** | `GRDBTransactionRepository`, `GRDBLedgerRepository`, `GRDBBankRepository` |
| **Infrastructure** | `DatabaseManager` (DB lifecycle + migrations), `AppContainer` (composition root) |
| **Services** | `TransactionImportPipeline`, `TransactionDeduplicator`, `GRDBSpendingService` |
| **Logging** | `FinanceLogger`, `OperationContext`, `PerformanceTimer` |
| **Errors** | `DatabaseError`, `FinanceError`, `ImportError`, `RepositoryError`, `ValidationError`, `ParsingError` |
| **Utilities** | `MoneyFormatting`, `CurrencySymbol`, `BINParser` |

#### FinanceUI
| | |
|-|-|
| **Design tokens** | `AppColors` (adaptive light/dark), `AppTypography` (+ `Style` enum for scaling), `AppSpacing`, `AppShadows`, `AppAnimation`, `AppRadius` |
| **Adaptive system** | `FDSBreakpoint`, `FDSScale`, `FDSScaleModifier` (`.fdsAdaptive()`), `FDSFontModifier` (`.fdsFont(.style)`) |
| **FDS components** | All `FDS*` components (cards, rows, chips, inputs, etc.) |
| **Modifiers** | `CardStyleModifier`, `GlassStyleModifier`, `HoverEffectModifier`, etc. |
| **Extensions** | `Banks+SwiftUI.swift` (`tintColor: Color`) |

#### FinanceIntelligence
| | |
|-|-|
| **Public API (Phase 3)** | `IntelligenceRequest`, `IntelligenceResponse`, `TransactionIntelligenceService` protocol |
| **Categorization** | `CoreMLCategorizer`, `RuleBasedCategorizer`, `PostProcessingPipeline`, `IntentClassifier` |
| **Behavior** | `SalaryAnalyzer`, `CashflowAnalyzer`, `FinancialRoutineDetector` |
| **ML infra** | `ModelManager`, `ModelDownloadManager`, `EmbeddingGenerator`, `LocalLLMRuntime` |
| **Persistence** | Own GRDB models via `DatabaseManager.shared.dbQueue` (injected, never self-constructed) |

#### FinanceCLI *(new)*
| | |
|-|-|
| **Commands** | `parse` (JSON output), `import` (persist to DB), `analyze` (run intelligence), `pipeline` (end-to-end) |
| **Pattern** | Uses `AppContainer.shared` — same composition root as the app |

---

## 3. Key Design Decisions

### Decision 1: AppContainer stays in FinanceCore

`AppContainer` is the composition root that creates all repositories, the import pipeline, and the spending service. Both `FinanceOSMac` and `FinanceCLI` need identical service instances pointing to the same database. Keeping `AppContainer` in `FinanceCore` means both targets call `AppContainer.shared` with zero duplication.

**Alternative considered:** Move `AppContainer` to `FinanceOSMac` and create a `CLIContainer` in `FinanceCLI`. Rejected — duplicate composition logic, two diverging container implementations.

### Decision 2: FinanceParsers dependency stays in FinanceCore

`FinanceCore`'s import pipeline (`TransactionImportPipeline`, `ImportSession`) directly uses `FinanceParsers` types. The import pipeline is core functionality — shared by both app and CLI. Separating it out adds a new package for minimal benefit.

**Alternative considered:** Extract import pipeline into a new `FinanceImport` package. Rejected — unnecessary package proliferation for functionality that is already well-scoped.

### Decision 3: FinanceIntelligence retains direct GRDB dependency

`FinanceIntelligence` own GRDB models (`GRDBGraphNode`, `GRDBFeedbackEvent`, etc.) implement `FetchableRecord`/`PersistableRecord` — these GRDB protocols require GRDB as a direct dep. SPM does not propagate transitive imports.

**Constraint enforced instead:** `FinanceIntelligence` never creates its own `DatabaseQueue`. All database access uses the `DatabaseQueue` injected via `IntelligenceServiceConfiguration(databaseQueue:)`, which callers always obtain from `DatabaseManager.shared.dbQueue`. Single source of truth, single SQLite file.

### Decision 4: Adaptive tokens use `Color.primary` for opacity-based fills

`Fill.*`, `Glass.*`, `Border.*` tokens use `Color.white.opacity(x)` — invisible on light backgrounds. SwiftUI's `Color.primary` is black in light mode and white in dark mode. Replacing `Color.white` with `Color.primary` in all opacity-based tokens is a one-token change that makes them work in both modes without NSColor boilerplate.

### Decision 5: Static typography tokens kept as backward-compatible aliases

Migrating all 122 FinanceOSMac source files from `.font(AppTypography.xxx)` to `.fdsFont(.xxx)` in a single PR is a large blast radius. Old static tokens are kept as base-scale aliases. Callsites migrate incrementally; new code always uses `.fdsFont()`.

### Decision 6: TargetCreationState moves to FinanceOSMac

Its own doc comment says "transient UI state accumulated during the 'add ledger' flow. Lives in a ViewModel." It was placed in FinanceCore as a convenience — but it imports `FinanceParsers` for `ParsedStatement`, it is exclusively used by `ImportViewModel`, and it has no business being in a shared core package.

---

## 4. Adaptive Token System Overview

### Problem

- macOS displays range from 1280pt (MacBook 13") to 3008pt (Pro Display XDR) logical width
- Design tokens are fixed values — `Font.system(size: 36)` is the same on every screen
- Users on large external displays see undersized text and cramped layouts

### Solution

A three-layer system, entirely within `FinanceUI`, applied via a single root-level modifier:

```
NSScreen.main.frame.width
        │
        ▼
FDSBreakpoint (compact / regular / large / xlarge)
        │  typographyScale: 0.875 / 1.0 / 1.1 / 1.2
        │  spacingScale:    0.875 / 1.0 / 1.125 / 1.25
        ▼
FDSScale (struct in SwiftUI environment)
        │
        ▼
.fdsFont(.displayLarge)  →  Font.system(size: 36 * scale, ...)
.fdsPadding(.all, AppSpacing.md)  →  padding(16 * scale)
```

Root modifier call (once, in `FinanceOSMacApp`):
```swift
ContentView().fdsAdaptive()
```

Auto-updates on `NSApplication.didChangeScreenParametersNotification` (external display connect/disconnect).

### Color Adaptation

| Token group | Strategy |
|-------------|----------|
| System semantic (`surface`, `surface2`, `surface3`) | Already adaptive via `NSColor` — no change |
| Opacity-based (`Fill.*`, `Glass.*`, `Border.*`) | `Color.white.opacity(x)` → `Color.primary.opacity(x)` |
| Custom RGB (`base`, `Text.*`) | NSColor appearance-based initializer (explicit dark + light pair) |
| Brand accents | Fixed — same value in both modes |
| Shadows | `Color.black.opacity(x)` — standard macOS pattern, acceptable both modes |

---

## 5. Cross-Cutting Invariants

Rules that must hold permanently, enforced by `make lint-architecture` in CI.

| # | Invariant |
|---|-----------|
| 1 | `FinanceCore` production sources: zero `import SwiftUI` |
| 2 | `FinanceIntelligence` production sources: zero `import SwiftUI` |
| 3 | `FinanceParsers` production sources: zero `import SwiftUI` |
| 4 | `FinanceCLI` production sources: zero `import SwiftUI` |
| 5 | `FinanceTesting` appears only in `testTarget(...)` across all Package.swift files |
| 6 | `FinanceParsers` depends on nothing (zero entries in `dependencies:`) |
| 7 | `FinanceIntelligence` never constructs a `DatabaseQueue` directly |
| 8 | All public intelligence API calls go through `IntelligenceRequest` / `IntelligenceResponse` |

**CI enforcement script** (`make lint-architecture`):

```bash
#!/bin/bash
set -e
PACKAGES=(FinanceCore FinanceParsers FinanceIntelligence FinanceCLI)
for pkg in "${PACKAGES[@]}"; do
  count=$(grep -r "^import SwiftUI" "Packages/$pkg/Sources/" --include="*.swift" 2>/dev/null | wc -l | tr -d ' ')
  if [ "$count" -gt 0 ]; then
    echo "FAIL: SwiftUI import found in $pkg:"
    grep -rn "^import SwiftUI" "Packages/$pkg/Sources/" --include="*.swift"
    exit 1
  fi
done
echo "Architecture lint: PASSED"
```

---

## 6. Phasing Strategy

Phases are ordered to minimize risk. Each is independently shippable via its own PR.

```
Phase 1 ──► Phase 2 ──► Phase 3
  │                       │
  │  (Phase 2 benefits     │  (Phase 3 deepest
  │   from clean Core)     │   refactor, highest risk)
  ▼                       ▼
Unblock CLI            Clean Intelligence API
  builds                  + Persistence
```

| Phase | Trigger to start | Blocks |
|-------|-----------------|--------|
| 1 | Immediately — no prerequisites | Phase 2 (clean Core makes CLI simpler) |
| 2 | Phase 1 merged | Nothing (independently useful) |
| 3 | Phase 1 merged | Nothing (can overlap with Phase 2) |

---

## 7. Risk Assessment

| Phase | Risk Level | Top Risk | Mitigation |
|-------|-----------|----------|------------|
| 1 — UI contamination | Low | Missed consumer of moved type → compile failure | Fix file-by-file; build after each move |
| 1 — Adaptive tokens | Medium | `.fdsFont()` callsite migration is large (~122 files) | Keep static aliases; migrate incrementally; new code uses `.fdsFont()` from day one |
| 2 — FinanceCLI | Medium | `AppContainer`/`DatabaseManager` headless init path | Smoke test; add `--db-path` override for path resolution |
| 3 — Intelligence API | High | Breaking change to public protocol surface | `@available(*, deprecated)` shims for all old methods during transition window |
| 3 — Migration ownership | Medium | Intelligence tables not created before service init | Move migration SQL to `AppMigration`; `DatabaseManager` always runs migrations first |

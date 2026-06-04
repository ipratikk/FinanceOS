# FinanceOS Package Segregation — PRD

**Author:** Pratik Goel  
**Date:** 2026-06-04  
**Status:** Approved  
**Type:** Product Requirements Document  
**Related:** [HLD](2026-06-04-package-segregation-hld.md) · [LLD](2026-06-04-package-segregation-lld.md)

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [Problem Statement](#2-problem-statement)
3. [Goals](#3-goals)
4. [Package Responsibility Charter](#4-package-responsibility-charter)
5. [Non-Goals](#5-non-goals)
6. [Success Criteria](#6-success-criteria)
7. [Phasing Overview](#7-phasing-overview)
8. [Risks & Dependencies](#8-risks--dependencies)

---

## 1. Executive Summary

FinanceOS is structured as a multi-package Swift workspace. As the codebase has grown, package boundary violations have accumulated: UI code has leaked into non-UI packages, intelligence code carries SwiftUI imports, the app cannot run headlessly, and no unified CLI exists for pipeline operations.

This initiative enforces clear package contracts, establishes a unified headless CLI, adds light/dark mode support to the design system, and introduces screen-adaptive token scaling for macOS — without breaking existing functionality.

---

## 2. Problem Statement

### 2.1 Current Harms

| Symptom | Impact |
|---------|--------|
| `FinanceCore` imports `SwiftUI` (via `Design/` folder) | Core package cannot be linked into headless CLI or server targets |
| `FinanceIntelligence` imports `SwiftUI` (via `EnvironmentKey.swift`) | Intelligence package not portable to non-UI contexts |
| No unified `FinanceCLI` | Parse → Import → Categorize pipeline requires building and launching the full macOS app |
| `FinanceTesting` in `FinanceIntelligence` production target | Test helpers ship in production binary |
| Design tokens are dark-mode only | App is unusable in macOS light mode |
| Font sizes fixed regardless of display | Text appears too small on large external displays (iMac, Studio Display) |

### 2.2 Root Cause

Package responsibilities were never formally defined. Code was added where it compiled, not where it belonged. The result is a tangled dependency graph where "core" packages pull in platform UI frameworks, preventing reuse across targets.

---

## 3. Goals

### Primary Goals

1. **Clean package boundaries** — each package has a single, documented responsibility; no package imports SwiftUI unless it is explicitly a UI package
2. **Headless pipeline** — the full data pipeline (parse → import → categorize) runs without launching the macOS app
3. **Light/dark mode** — all design tokens support both macOS appearance modes
4. **Screen-adaptive tokens** — typography and spacing scale appropriately across MacBook → iMac → Studio Display logical screen widths
5. **iOS/macOS portable foundation** — `FinanceCore`, `FinanceParsers`, `FinanceIntelligence` can be imported on iOS targets without modification

### Secondary Goals

6. **FinanceIntelligence as a typed API** — intelligence consumers use explicit request/response types; internal implementation details are not part of the public contract
7. **Enforceable architecture** — boundary rules are verified by a CI lint script, not just convention

---

## 4. Package Responsibility Charter

### FinanceParsers
- **Owns:** Parser protocol, bank-specific parser implementations, format detection, `FinanceParserCLI`
- **Does not own:** SwiftUI, GRDB, any FinanceCore types
- **Depends on:** Nothing (standalone)

### FinanceCore
- **Owns:** Domain models, repository protocols + GRDB implementations, `DatabaseManager`, `AppContainer`, import pipeline, spending service, logging, error types, utilities
- **Does not own:** SwiftUI, design tokens, ViewModel state types
- **Depends on:** `FinanceParsers`, `GRDB`

### FinanceUI
- **Owns:** Design tokens (`AppColors`, `AppTypography`, `AppSpacing`, `AppShadows`, `AppAnimation`, `AppRadius`), Finance Design System (FDS) components, view modifiers, SwiftUI-only extensions on FinanceCore types, adaptive scaling system (`FDSBreakpoint`, `FDSScaleModifier`)
- **Does not own:** ViewModels, business logic, GRDB, navigation
- **Depends on:** `FinanceCore`

### FinanceIntelligence
- **Owns:** Categorization pipeline, behavior analysis (salary, cashflow, routines), embeddings, knowledge graph, entity resolution, recurring detection, merchant normalization, ML infrastructure, feedback, typed request/response API (`IntelligenceRequest` / `IntelligenceResponse`)
- **Does not own:** SwiftUI, `EnvironmentKey`, `FinanceTesting` in production target
- **Depends on:** `FinanceCore`, `swift-transformers`, `ZIPFoundation`, `mlx-swift`, `GRDB`

### FinanceCLI *(new)*
- **Owns:** Unified headless executable with `parse`, `import`, `analyze`, and `pipeline` commands
- **Does not own:** SwiftUI, any UI dependency
- **Depends on:** `FinanceCore`, `FinanceParsers`, `FinanceIntelligence`, `swift-argument-parser`

### FinanceTesting
- **Owns:** Shared test helpers, fixtures, golden JSON, test mocks
- **Usage rule:** Imported **only** in `testTarget(...)` — never in production targets
- **Depends on:** `FinanceCore`, `FinanceParsers`

### FinanceOSMac *(App target, not a Package)*
- **Owns:** SwiftUI Views, ViewModels, navigation, app entry point, window/scene configuration, `CategorizationScheduler`, SwiftUI `EnvironmentKey` definitions for intelligence and scheduler services, `TargetCreationState`
- **Depends on:** `FinanceCore`, `FinanceUI`, `FinanceIntelligence`

---

## 5. Non-Goals

The following are explicitly out of scope for this initiative:

- Restructuring `FinanceParsers` internal implementation
- Changing GRDB schema, migration ordering, or SQL
- Introducing a networking, sync, or cloud layer
- Moving ViewModels from `FinanceOSMac` into `FinanceUI`
- Renaming existing public API symbols (other than types being relocated)
- Adding iOS-specific UI targets or a `FinanceOSiOS` app target
- Full ML training pipeline changes
- Adding new financial features or screens

---

## 6. Success Criteria

### Architecture
- [ ] `FinanceCore` contains zero `import SwiftUI` in production sources
- [ ] `FinanceIntelligence` contains zero `import SwiftUI` in production sources
- [ ] `FinanceParsers` contains zero `import SwiftUI` in production sources
- [ ] `FinanceCLI` contains zero `import SwiftUI` in production sources
- [ ] `FinanceTesting` appears only in `testTarget(...)` in all Package.swift files
- [ ] `make lint-architecture` passes in CI with zero violations

### Functionality
- [ ] `FinanceCLI pipeline <file>` successfully parses, imports, and categorizes a statement without opening the app
- [ ] App builds and runs in macOS Light Mode without visual regressions
- [ ] App builds and runs in macOS Dark Mode (no regression from current)
- [ ] All existing unit and snapshot tests pass

### Design System
- [ ] All `AppColors` tokens resolve correctly in Light and Dark mode (visual QA)
- [ ] Typography scales visibly between MacBook 13" (regular) and large displays (large/xlarge breakpoints)
- [ ] `.fdsAdaptive()` applied at app root updates on display parameter changes

### Intelligence API (Phase 3)
- [ ] `TransactionIntelligenceService` protocol exposes only `IntelligenceRequest` / `IntelligenceResponse`
- [ ] No internal FinanceIntelligence types exposed in public API surface
- [ ] All FinanceOSMac call sites migrated to typed request/response pattern

---

## 7. Phasing Overview

Work is split into three independent, sequentially shippable phases. Each phase can be merged and shipped without requiring the next phase to be complete.

| Phase | Title | Scope | Risk |
|-------|-------|-------|------|
| 1 | Eliminate UI Contamination + Adaptive Token System | Move `Design/` to FinanceUI; move `TargetCreationState` + `EnvironmentKey` to FinanceOSMac; fix `FinanceTesting` prod dep; add light/dark + screen-adaptive scaling | Low–Medium |
| 2 | Create FinanceCLI Package | New `FinanceCLI` package with `parse`, `import`, `analyze`, `pipeline` commands; headless `AppContainer` init | Medium |
| 3 | FinanceIntelligence API Boundary + Persistence Consolidation | `IntelligenceRequest`/`IntelligenceResponse` typed API; single-DatabaseQueue enforcement; migrate DB migrations to `AppMigration` | High |

**Recommended sequence:** Complete Phase 1 before Phase 2 (CLI benefits from clean FinanceCore). Phase 3 is independent of Phase 2 but should follow Phase 1.

---

## 8. Risks & Dependencies

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Callsite breakage when moving Design/ tokens | Low | Medium | Each file move verified by build before next move |
| Headless `AppContainer` init fails (uses SwiftUI-owned paths) | Medium | Medium | Audit `DatabaseManager` path resolution; add `--db-path` CLI override |
| Phase 3 protocol change breaks FinanceOSMac ViewModels | High | High | `@available(*, deprecated)` shims keep old methods callable during migration |
| SwiftUI `Color.primary` behaves unexpectedly in older macOS | Low | Low | Test on macOS 14 minimum target; fallback to NSColor if needed |
| Screen parameter notification not fired for all display changes | Low | Low | `.onAppear` also triggers scale computation as fallback |

# FinanceOS Production-Grade Refactor - Master Checklist

**Total Effort:** 4 weeks | **Parallelizable:** Weeks 1-2 (A/B track)  
**Commits:** ~15 | **Risk Level:** Medium (transactional imports high-risk)  
**Last Updated:** 2026-05-20

---

## Phase Timeline

- **Week 1 (Days 1-5):** Foundation - Typed IDs, enums, snapshots
- **Week 2 (Days 6-12):** State Management - ViewModels, @MainActor, form consolidation
- **Week 3 (Days 13-17):** Concurrency & Workflows - Coordinators, transactional imports
- **Week 4 (Days 18-20):** Enforcement - SwiftLint, docs, audit

---

## Phase 1: Foundation (Days 1-5)

**Goal:** Type safety foundation. Zero dependencies on downstream phases.

- [ ] Create TypedIDs.swift (LedgerID, TransactionID, ImportSessionID, StatementID, CardProductID)
- [ ] Create AccountType.swift enum
- [ ] Update Ledger model: typed IDs + AccountType
- [ ] Create ImportFlowState.swift enum
- [ ] Create ParsedStatementSnapshot.swift (immutable)
- [ ] Create ParsedTransactionSnapshot.swift (immutable)
- [ ] Update GRDB mappers to use typed IDs
- [ ] Test typed ID encoding/decoding
- [ ] Verify backward-compatible DB loading

**Commits:**
1. "feat: Add typed ID wrappers (LedgerID, TransactionID, ImportSessionID, CardProductID)"
2. "feat: Add AccountType enum, replace stringly-typed accountType: String"
3. "refactor: Update Ledger model to use typed IDs"
4. "feat: Add ImportFlowState enum for deterministic import workflows"
5. "feat: Add immutable snapshots (ParsedStatementSnapshot, ParsedTransactionSnapshot)"

**Success Criteria:**
- [ ] All typed IDs compile and encode/decode correctly
- [ ] Ledger loads from DB with typed IDs (backward-compatible)
- [ ] ImportFlowState covers all import states
- [ ] Snapshots are Equatable, Hashable, Sendable

---

## Phase 2: State Management (Days 6-12)

**Goal:** Consolidate form state, add @MainActor, move 61 @State to VMs.

**Depends On:** Phase 1 complete

### Sub-Phase 2A: ViewModel Creation & MainActor (Parallel track, days 6-9)

- [ ] Create CardEditViewModel
- [ ] Create LedgerForm model (unified)
- [ ] Add @MainActor to AccountsViewModel
- [ ] Add @MainActor to CardsViewModel
- [ ] Add @MainActor to TransactionsViewModel
- [ ] Add @MainActor to LedgerDetailViewModel
- [ ] Test MainActor isolation on all VMs

**Commits:**
1. "feat: Add unified LedgerForm model (consolidates Ledger/TargetCreationState/CardEditFormState)"
2. "feat: Add CardEditViewModel, consolidate form state"
3. "refactor: Introduce @MainActor isolation to all ViewModels"

### Sub-Phase 2B: Import State Machine (Sequential after 2A, days 9-12)

- [ ] Refactor ImportViewModel to use ImportFlowState
- [ ] Add task cancellation infrastructure (currentTask property)
- [ ] Implement selectFilesAndAdvance() with parsing
- [ ] Implement performImport() with progress tracking
- [ ] Implement cancelImport() with cleanup
- [ ] Add state transition guards (canCancel, canImport checks)
- [ ] Test state machine transitions (20+ tests)
- [ ] Test task cancellation at all states

**Commits:**
1. "refactor: Refactor ImportViewModel to use ImportFlowState, add task cancellation"
2. "test: Add comprehensive ImportFlowState state machine tests"

**Success Criteria:**
- [ ] ImportFlowState replaces all fragmented state (isLoading, errorMessage, selectedSource, etc.)
- [ ] All ViewModels @MainActor-isolated
- [ ] Zero @State properties for persistent state in Views
- [ ] Task cancellation working at parse + import states

---

## Phase 3: Concurrency & Workflows (Days 13-17)

**Goal:** Structured concurrency, Sendable audit, coordinators, transactional imports.

**Depends On:** Phase 2 complete

### Sub-Phase 3A: Sendable & Structured Concurrency (days 13-14)

- [ ] Audit all models for Sendable conformance
- [ ] Add Sendable to Ledger, Transaction, CardMetadata, ParsedStatement
- [ ] Implement structured concurrency in AccountsViewModel (async let)
- [ ] Implement task cancellation in all async methods
- [ ] Document non-Sendable dependencies (GRDB, DatabaseManager)
- [ ] Run Sendable compiler checks (swift -typecheck-only)

**Commits:**
1. "refactor: Add Sendable conformance across all models"
2. "refactor: Implement structured concurrency with task cancellation in ViewModels"

### Sub-Phase 3B: Workflow Coordinators (days 15-16)

- [ ] Create ImportWorkflowCoordinator
- [ ] Create TransactionWorkflowCoordinator (optional for Phase 1)
- [ ] Wire coordinators into Views (environment injection)
- [ ] Test state transitions via coordinator
- [ ] Test cancellation propagation

**Commits:**
1. "feat: Add ImportWorkflowCoordinator for deterministic import orchestration"

### Sub-Phase 3C: Transactional Imports (HIGH RISK, day 17)

- [ ] Create TransactionalImportPipeline protocol extension
- [ ] Implement GRDB transaction wrapper (DatabaseManager.write with BEGIN/COMMIT/ROLLBACK)
- [ ] Update ImportViewModel.importWithTransaction() to use transactions
- [ ] Implement duplicate detection inside transaction (atomic all-or-nothing)
- [ ] Add serialization lock to prevent concurrent imports
- [ ] Test multi-file atomic import
- [ ] Test rollback on error
- [ ] Test duplicate detection safety

**Commits:**
1. "feat: Implement transactional import boundaries with rollback support"
2. "test: Add transactional import integration tests"

**Success Criteria:**
- [ ] All models Sendable
- [ ] All ViewModels structured concurrency with cancellation
- [ ] Coordinators handle all state transitions
- [ ] Multi-file imports atomic (all succeed or all rollback)
- [ ] Duplicate detection runs inside transaction
- [ ] Concurrent import attempts blocked

---

## Phase 4: Enforcement (Days 18-20)

**Goal:** Architectural enforcement, documentation, cleanup.

**Depends On:** Phase 3 complete

- [ ] Add SwiftLint custom rules (forbidden imports, typed ID usage)
- [ ] Add module boundary validation (Views ≠ GRDB)
- [ ] Update ARCHITECTURE.md with state machine diagrams
- [ ] Document typed ID usage patterns
- [ ] Document workflow coordinator patterns
- [ ] Create migration guide for plugins
- [ ] Run full lint check (should be zero violations)
- [ ] Final code review & audit

**Commits:**
1. "infra: Add SwiftLint rules for architectural enforcement"
2. "docs: Update ARCHITECTURE.md with state machines and typed ID patterns"

**Success Criteria:**
- [ ] Zero lint violations
- [ ] ARCHITECTURE.md updated with state machines
- [ ] All typed ID patterns documented
- [ ] All new patterns have migration guides

---

## Implementation Notes

### File Locations

**New Files (FinanceCore):**
- `Packages/FinanceCore/Sources/FinanceCore/Types/TypedIDs.swift`
- `Packages/FinanceCore/Sources/FinanceCore/Types/AccountType.swift`
- `Packages/FinanceCore/Sources/FinanceCore/Models/LedgerForm.swift`
- `Packages/FinanceCore/Sources/FinanceCore/Models/ParsedStatementSnapshot.swift`
- `Packages/FinanceCore/Sources/FinanceCore/Services/ImportFlowState.swift`

**New Files (FinanceOSMac):**
- `Apps/FinanceOSMac/FinanceOSMac/Presentation/Cards/CardEditViewModel.swift`
- `Apps/FinanceOSMac/FinanceOSMac/Presentation/Import/ImportWorkflowCoordinator.swift`

**Modified Files (Phase 1):**
- `Packages/FinanceCore/Sources/FinanceCore/Models/Ledger.swift`
- `Packages/FinanceCore/Sources/FinanceCore/Models/Transaction.swift`
- `Packages/FinanceCore/Sources/FinanceCore/Services/CardDatabase.swift` (GRDB mapper)

**Modified Files (Phase 2):**
- `Apps/FinanceOSMac/FinanceOSMac/Presentation/Import/ImportViewModel.swift`
- `Apps/FinanceOSMac/FinanceOSMac/Presentation/Cards/CardEditView.swift`
- `Apps/FinanceOSMac/FinanceOSMac/Presentation/Accounts/AccountsViewModel.swift`
- `Apps/FinanceOSMac/FinanceOSMac/Presentation/Cards/CardsViewModel.swift`

**Modified Files (Phase 3):**
- `Packages/FinanceCore/Sources/FinanceCore/Services/TransactionRepository.swift`
- `Packages/FinanceCore/Sources/FinanceCore/Services/DatabaseManager.swift`

### Testing Strategy

Per Phase:
1. **Phase 1:** Typed ID encoding/decoding (10 tests), AccountType mapping (5 tests), Snapshot equality (5 tests)
2. **Phase 2:** Form bidirectional mapping (15 tests), MainActor enforcement (4 tests), State transitions (20 tests)
3. **Phase 3:** Sendable conformance (compiler check), Structured concurrency (10 tests), Transactional imports (8 tests)
4. **Phase 4:** SwiftLint rules enforcement (integration test)

### Rollback Plan

**Phase 1:** Revert TypedID wrappers to UUID, AccountType back to String enum or case value
**Phase 2:** Keep old ImportViewModel, fallback Views to legacy state
**Phase 3:** Disable transactional imports, revert to per-file error handling
**Phase 4:** Remove SwiftLint rules

---

## Progress Tracking

| Phase | Status | Completion | Notes |
|-------|--------|-----------|-------|
| 1: Foundation | ⬜ Not Started | 0% | Awaiting kickoff |
| 2: State Mgmt | ⬜ Not Started | 0% | Depends on Phase 1 |
| 3: Concurrency | ⬜ Not Started | 0% | Depends on Phase 2 |
| 4: Enforcement | ⬜ Not Started | 0% | Depends on Phase 3 |

---

## Parallel Work Opportunities

**Week 1-2:** 
- Engineer A: Phase 1 (TypedIDs, enums, models) + Phase 2A (ViewModels, @MainActor)
- Engineer B: Test scaffolding, documentation updates, code review prep

**Week 2-3:**
- Engineer A: Phase 2B (ImportViewModel refactor)
- Engineer B: Phase 3A (Sendable audit, structured concurrency)

**Week 3-4:**
- Engineer A & B together: Phase 3C (Transactional imports - requires careful coordination)
- Review & Phase 4 enforcement

---

## Risk Mitigation

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|-----------|
| TypedID DB migration | Low | Medium | Backward-compatible init helpers, data verification |
| ImportViewModel refactor breaks | Medium | High | Parallel old/new, gradual View transition, comprehensive tests |
| Transactional import deadlock | Medium | High | Serialization lock, lock testing, detailed logging |
| MainActor compiler errors | Low | Low | Gradual rollout, use warnings first |
| Sendable conformance discovery | Low | Low | Compiler check, incremental fixes |


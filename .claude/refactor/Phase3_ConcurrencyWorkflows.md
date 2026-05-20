# Phase 3: Concurrency & Workflows - Sendable Audit & Transactional Imports

**Duration:** Days 13-17  
**Commits:** 3  
**Risk:** High (transactional imports)  
**Blocking:** Phase 4  
**Depends On:** Phase 2 complete

---

## Overview

Harden concurrency via Sendable conformance, implement structured concurrency, create workflow coordinators, introduce transactional import boundaries with atomic guarantees.

---

## Sub-Phase 3A: Sendable & Structured Concurrency (Days 13-14)

### Task 1: Sendable Audit & Conformance

**Files to Audit:**

**Models (add Sendable):**
- `Packages/FinanceCore/Sources/FinanceCore/Models/Ledger.swift`
- `Packages/FinanceCore/Sources/FinanceCore/Models/Transaction.swift`
- `Packages/FinanceCore/Sources/FinanceCore/Models/CardMetadata.swift`
- `Packages/FinanceCore/Sources/FinanceCore/Models/ParsedStatement.swift`
- `Packages/FinanceCore/Sources/FinanceCore/Models/ParsedTransaction.swift`
- `Packages/FinanceCore/Sources/FinanceCore/Models/ImportSession.swift`
- `Packages/FinanceCore/Sources/FinanceCore/Models/TargetCreationState.swift` (to be removed in Phase 4)

**DTOs/Snapshots (add Sendable):**
- `Packages/FinanceCore/Sources/FinanceCore/Models/LedgerForm.swift`
- `Packages/FinanceCore/Sources/FinanceCore/Models/ParsedStatementSnapshot.swift`
- `Packages/FinanceCore/Sources/FinanceCore/Models/TransactionSnapshot.swift` (new)
- `Packages/FinanceCore/Sources/FinanceCore/Types/ImportFlowState.swift`

**Checklist:**
- [ ] Audit Ledger: all properties Codable, Sendable (PASS)
- [ ] Audit Transaction: all properties Codable, Sendable (PASS)
- [ ] Audit CardMetadata: all properties Sendable (PASS)
- [ ] Audit ParsedStatement: verify ParsedMetadata, ParsedTransaction Sendable
- [ ] Audit ParsedTransaction: verify all properties Sendable
- [ ] Audit ImportSession: identify mutable @ObservationIgnored properties (FAIL - keep MainActor)
- [ ] Document non-Sendable dependencies:
  - [ ] GRDB database connections (thread-bound, isolate)
  - [ ] DatabaseManager (owns DB lifecycle, isolate)
  - [ ] File handles in parsers (thread-safe wrappers)
- [ ] Add Sendable conformance to all Sendable types
- [ ] Run compiler check: `swift -typecheck-only` (should show no violations)

**Code Template:**
```swift
// Before
struct Ledger: Identifiable, Codable {
    // ...
}

// After
struct Ledger: Identifiable, Codable, Sendable {
    let id: LedgerID
    let bankId: UUID
    let kind: LedgerKind
    // All properties are Sendable, no mutable references
}

// Non-Sendable document
/*
 Non-Sendable Dependencies:
 
 - GRDB DatabaseManager: thread-bound, isolate to serial DispatchQueue
   Not Sendable: owns database connections
   Solution: nonisolated(unsafe) access in protocols, MainActor for UI-bound usage
 
 - ImportSession: contains @ObservationIgnored mutable properties
   Not Sendable: mutable state during import flow
   Solution: keep @MainActor isolation, use snapshots for state passing
 */
```

**Commit Message:**
```
refactor: Add Sendable conformance across all models

- Ledger, Transaction, CardMetadata: Sendable
- LedgerForm, ParsedStatementSnapshot: Sendable
- ImportFlowState, ImportError, ImportProgress: Sendable
- Compiler enforces thread-safety via Sendable trait
- Document non-Sendable dependencies (GRDB, DatabaseManager)
- Isolate non-Sendable types to MainActor or serial DispatchQueue
- Zero Sendable warnings in compiler output
```

---

### Task 2: Structured Concurrency Implementation

**Files to Refactor:**
- `Apps/FinanceOSMac/FinanceOSMac/Presentation/Accounts/AccountsViewModel.swift`
- `Apps/FinanceOSMac/FinanceOSMac/Presentation/Cards/CardsViewModel.swift`
- `Apps/FinanceOSMac/FinanceOSMac/Presentation/Transactions/TransactionsViewModel.swift`
- `Apps/FinanceOSMac/FinanceOSMac/Presentation/Import/ImportViewModel.swift`

**Checklist:**
- [ ] Replace concurrent Task {} blocks with async let
- [ ] Use Task { } only for fire-and-forget (background work)
- [ ] Use async let for concurrent operations that need results
- [ ] Add Task.checkCancellation() in loops
- [ ] Handle CancellationError in all catch blocks
- [ ] Implement task cancellation in cancellable methods
- [ ] Test concurrent load scenarios (no race conditions)

**Example Refactor (AccountsViewModel):**

```swift
// Before: Sequential, no concurrency
func loadLedgers() {
    Task {
        do {
            let ledgers = try await ledgerRepository.fetchLedgers()
            self.ledgers = ledgers
            
            let totalBalance = try await balanceCalculator.calculateTotal(ledgers)
            self.totalBalance = totalBalance
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
}

// After: Structured concurrency with async let
func loadLedgers() {
    currentTask?.cancel()
    isLoading = true
    
    currentTask = Task {
        do {
            async let ledgers = ledgerRepository.fetchLedgers()
            async let totalBalance = balanceCalculator.calculateTotal(try await ledgers)
            
            self.ledgers = try await ledgers
            self.totalBalance = try await totalBalance
            
            self.isLoading = false
        } catch is CancellationError {
            // Silently cancelled
        } catch {
            self.errorMessage = error.localizedDescription
            self.isLoading = false
        }
    }
}

func cancelLoad() {
    currentTask?.cancel()
    currentTask = nil
}
```

**Commit Message:**
```
refactor: Implement structured concurrency with task cancellation in ViewModels

- Replace sequential await with async let for concurrent operations
- Implement task cancellation in loadLedgers, refreshBalance, etc.
- Handle CancellationError explicitly
- Add currentTask property for cancellation tracking
- Task.checkCancellation() in loops
- Prevents race conditions in concurrent load/refresh
- Enables graceful cancellation on view dismiss
```

---

## Sub-Phase 3B: Workflow Coordinators (Days 15-16)

### Task 3: Create ImportWorkflowCoordinator

**File:** `Apps/FinanceOSMac/FinanceOSMac/Presentation/Import/ImportWorkflowCoordinator.swift` (new)

**Checklist:**
- [ ] Create ImportWorkflowCoordinator class
- [ ] Add @MainActor decorator
- [ ] Properties:
  - [ ] @ObservationIgnored viewModel: ImportViewModel
  - [ ] @ObservationIgnored navigator: AppNavigator
  - [ ] @ObservationIgnored currentTask: Task<Void, Never>?
  - [ ] Computed: flowState (proxy to viewModel)
  - [ ] Computed: canCancel (proxy to flowState)
  - [ ] Computed: canImport (check preconditions)
- [ ] Public methods:
  - [ ] beginImportFlow()
  - [ ] selectSource(_ source: StatementSource) async
  - [ ] selectFiles(_ urls: [URL]) async
  - [ ] confirmImport(target: TransactionImportTarget) async
  - [ ] cancel()
- [ ] Private methods:
  - [ ] navigateToResults(_ result: ImportResult) async
- [ ] Test state transitions via coordinator
- [ ] Test cancellation propagation

**Code Template:**
```swift
@MainActor
final class ImportWorkflowCoordinator: Observable {
    @ObservationIgnored private let viewModel: ImportViewModel
    @ObservationIgnored private let navigator: AppNavigator
    @ObservationIgnored private var currentTask: Task<Void, Never>?
    
    var flowState: ImportFlowState { viewModel.flowState }
    var canCancel: Bool { flowState.canCancel }
    var canImport: Bool {
        if case let .review(statements, _, _) = flowState {
            return !statements.isEmpty
        }
        return false
    }
    
    init(viewModel: ImportViewModel, navigator: AppNavigator) {
        self.viewModel = viewModel
        self.navigator = navigator
    }
    
    // MARK: - State Transitions
    
    func beginImportFlow() {
        viewModel.flowState = .selectingSource
    }
    
    func selectSource(_ source: StatementSource) async {
        viewModel.flowState = .selectingFiles
    }
    
    func selectFiles(_ urls: [URL]) async {
        await viewModel.selectFilesAndAdvance(urls)
    }
    
    func confirmImport(target: TransactionImportTarget) async {
        currentTask?.cancel()
        currentTask = Task {
            await viewModel.performImport(target: target)
            
            if case let .completed(result) = viewModel.flowState {
                await navigateToResults(result)
            }
        }
    }
    
    func cancel() {
        currentTask?.cancel()
        viewModel.cancelImport()
        navigator.pop()
    }
    
    // MARK: - Private
    
    private func navigateToResults(_ result: ImportResult) async {
        navigator.push(.importComplete(result))
    }
}
```

**Usage in View:**
```swift
struct ImportView: View {
    @Environment(AppNavigator.self) var navigator
    @State var coordinator: ImportWorkflowCoordinator?
    
    var body: some View {
        if let coordinator {
            VStack {
                switch coordinator.flowState {
                case .selectingSource:
                    sourceSelectionView(coordinator)
                case .selectingFiles:
                    fileSelectionView(coordinator)
                case let .review(statements, _, duplicates):
                    reviewView(statements, duplicates, coordinator)
                // ...
                }
            }
        }
    }
    
    private func sourceSelectionView(_ coordinator: ImportWorkflowCoordinator) -> some View {
        Button("Select CSV") {
            Task {
                await coordinator.selectSource(.csv)
            }
        }
    }
}
```

**Commit Message:**
```
feat: Add ImportWorkflowCoordinator for deterministic import orchestration

- Orchestrates ImportViewModel state transitions
- Guards state transitions (canCancel, canImport checks)
- Handles navigation after import completion
- Centralizes import workflow logic
- Enables testing state machine independently of Views
- Task cancellation propagates through coordinator
```

---

## Sub-Phase 3C: Transactional Imports (HIGH RISK, Day 17)

### Task 4: Implement Transactional Import Boundaries

**File:** `Packages/FinanceCore/Sources/FinanceCore/Services/TransactionalImportPipeline.swift` (new)

**Checklist:**
- [ ] Define TransactionRepository.transaction() protocol
- [ ] Implement in GRDBTransactionRepository:
  - [ ] Acquire exclusive lock
  - [ ] BEGIN TRANSACTION
  - [ ] Execute block
  - [ ] COMMIT on success
  - [ ] ROLLBACK on error
  - [ ] Release lock
- [ ] Create ImportLock (serial DispatchQueue) for serialization
- [ ] Write comprehensive transaction tests:
  - [ ] Multi-file import (all succeed)
  - [ ] Multi-file import with error (all rollback)
  - [ ] Concurrent import attempts (second waits, then allowed)
  - [ ] Transaction isolation (duplicates detected before any insert)

**Code Template:**
```swift
// Protocol
protocol TransactionRepository {
    func transaction<T>(
        _ block: @escaping () async throws -> T
    ) async throws -> T
}

// Implementation
final class GRDBTransactionRepository: TransactionRepository {
    private let databaseManager: DatabaseManager
    private let importLock = DispatchSemaphore(value: 1)
    
    func transaction<T>(
        _ block: @escaping () async throws -> T
    ) async throws -> T {
        importLock.wait()
        defer { importLock.signal() }
        
        return try await databaseManager.dbQueue.write { database in
            do {
                try database.execute("BEGIN TRANSACTION")
                let result = try await block()
                try database.execute("COMMIT")
                return result
            } catch {
                try? database.execute("ROLLBACK")
                throw error
            }
        }
    }
}

// Usage in ImportViewModel
private func importWithTransaction(target: TransactionImportTarget) async throws -> ImportResult {
    return try await transactionRepository.transaction {
        // 1. Load existing transactions for duplicate detection
        let existing = try await transactionRepository.fetchTransactions()
        
        // 2. Detect ALL duplicates BEFORE any inserts
        var duplicateCount = 0
        for statement in parsedStatements {
            for transaction in statement.transactions {
                let hash = hashParsedTransaction(transaction)
                if existingHashes.contains(hash) {
                    duplicateCount += 1
                }
            }
        }
        
        guard duplicateCount == 0 else {
            throw ImportError.duplicatesDetected(count: duplicateCount)
        }
        
        // 3. Insert all transactions atomically
        var inserted = 0
        for statement in parsedStatements {
            for transaction in statement.transactions {
                let domainTransaction = try mapParsedTransaction(transaction, target: target)
                try await transactionRepository.insert(domainTransaction)
                inserted += 1
                
                let progress = ImportProgress(...)
                flowState = .importing(progress: progress)
            }
        }
        
        return ImportResult(inserted: inserted, skipped: 0)
    }
}
```

**Comprehensive Tests:**

```swift
// Test 1: Multi-file atomic import
func test_multiFileImport_allSucceed() async throws {
    let result = try await coordinator.importFiles([file1, file2, file3], target: ledgerId)
    
    XCTAssertEqual(result.inserted, 30)  // All 3 files imported
    let count = try await transactionRepository.fetchTransactions().count
    XCTAssertEqual(count, 30)
}

// Test 2: Rollback on error
func test_multiFileImport_errorRollback() async throws {
    // Insert will fail on file2 (duplicate key)
    try await coordinator.importFiles([file1, file2_dup, file3], target: ledgerId)
    
    // All should rollback
    let count = try await transactionRepository.fetchTransactions().count
    XCTAssertEqual(count, 0)
}

// Test 3: Serialized execution
func test_concurrentImports_serialized() async throws {
    let task1 = Task { try await coordinator.import(files1, target: ledger1) }
    let task2 = Task { try await coordinator.import(files2, target: ledger2) }
    
    let r1 = try await task1.value
    let r2 = try await task2.value
    
    // Both succeed, but second waits for first to complete
    XCTAssertEqual(r1.inserted + r2.inserted, 60)
}

// Test 4: Duplicate detection inside transaction
func test_duplicateDetection_atomic() async throws {
    // Insert existing transaction
    try await transactionRepository.insert(existingTxn)
    
    // Try import with duplicate
    let result = try await coordinator.import(
        [fileWithDuplicate],
        target: ledgerId
    )
    
    // Transaction rolled back, count unchanged
    let count = try await transactionRepository.fetchTransactions().count
    XCTAssertEqual(count, 1)  // Only original, none from failed import
}
```

**Commit Message:**
```
feat: Implement transactional import boundaries with rollback support

- Single database transaction for multi-file imports
- Atomic all-or-nothing semantics: all files succeed or all rollback
- Duplicate detection runs inside transaction (atomic check-then-insert)
- Serialized execution: only one import at a time (DispatchSemaphore)
- Comprehensive transaction tests (success, rollback, serialization, duplicate detection)
- Idempotency: re-running same import blocked by duplicate detection
- Prevents partial imports and data corruption from concurrent operations
```

---

## Validation Checklist

Before moving to Phase 4:

- [ ] All models Sendable (compiler verified)
- [ ] Non-Sendable dependencies documented
- [ ] All ViewModels using structured concurrency (async let, not Task)
- [ ] Task cancellation working in all VMs
- [ ] ImportWorkflowCoordinator created and integrated
- [ ] Transactional imports working (all tests passing)
- [ ] Multi-file imports atomic (no partial inserts)
- [ ] Duplicate detection atomic (check-then-insert inside transaction)
- [ ] Concurrent imports serialized (semaphore working)
- [ ] No lint violations
- [ ] Code review sign-off

---

## Success Criteria

- [x] All models Sendable
- [x] Structured concurrency with async let
- [x] Task cancellation at all states
- [x] Workflow coordinator orchestrates state transitions
- [x] Multi-file imports atomic (all-or-nothing)
- [x] Duplicate detection atomic
- [x] Concurrent imports serialized


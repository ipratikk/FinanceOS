# Phase 2: State Management - Consolidation & MainActor

**Duration:** Days 6-12  
**Commits:** 4  
**Risk:** Medium  
**Blocking:** Phase 3  
**Depends On:** Phase 1 complete

---

## Overview

Consolidate form state via LedgerForm, add @MainActor to all ViewModels, refactor ImportViewModel to use ImportFlowState, move 61 @State variables from Views to ViewModels.

---

## Sub-Phase 2A: ViewModel Creation & MainActor (Days 6-9)

### Task 1: Create LedgerForm

**File:** `Packages/FinanceCore/Sources/FinanceCore/Models/LedgerForm.swift` (new)

**Checklist:**
- [ ] Define LedgerForm struct (unified form for card/account creation/edit)
- [ ] Properties:
  - [ ] nickname: String
  - [ ] customName: String
  - [ ] cardType: CardNetwork
  - [ ] first4: String
  - [ ] last4: String
  - [ ] cardholderName: String
  - [ ] accountType: AccountType
  - [ ] selectedBank: Banks?
  - [ ] linkedLedgerId: LedgerID?
  - [ ] cardProductId: CardProductID?
- [ ] Make Equatable, Sendable
- [ ] Add init() for creation flows
- [ ] Add init(from ledger: Ledger) for edit flows
- [ ] Add toLedger(...) conversion method
- [ ] Write unit tests (roundtrip conversion, equality)
- [ ] Test GRDB usage (optional)

**Code Template:**
```swift
struct LedgerForm: Equatable, Sendable {
    var nickname: String = ""
    var customName: String = ""
    var cardType: CardNetwork = .other
    var first4: String = ""
    var last4: String = ""
    var cardholderName: String = ""
    var accountType: AccountType = .savings
    var selectedBank: Banks?
    var linkedLedgerId: LedgerID?
    var cardProductId: CardProductID?
    
    init() {}
    
    init(from ledger: Ledger) {
        nickname = ledger.nickname
        customName = ledger.displayName
        cardType = ledger.cardType ?? .other
        last4 = ledger.last4
        cardholderName = ledger.ownerName
        accountType = ledger.accountType ?? .savings
        cardProductId = ledger.cardProductId
        linkedLedgerId = ledger.linkedLedgerId
    }
    
    func toLedger(id: LedgerID, bankId: UUID, kind: LedgerKind, existing: Ledger?) -> Ledger {
        let now = existing?.createdAt ?? Date()
        return Ledger(
            id: id,
            bankId: bankId,
            kind: kind,
            displayName: customName.isEmpty ? nickname : customName,
            last4: last4,
            nickname: nickname,
            ownerName: cardholderName,
            createdAt: now,
            accountType: kind == .bankAccount ? accountType : nil,
            cardType: kind == .creditCard ? cardType : nil,
            cardProductId: cardProductId,
            bin: nil,
            linkedLedgerId: linkedLedgerId,
            isArchived: false,
            closingBalance: existing?.closingBalance,
            closingBalanceAsOf: existing?.closingBalanceAsOf
        )
    }
}
```

**Commit Message:**
```
feat: Add unified LedgerForm model (consolidates Ledger/TargetCreationState/CardEditFormState)

- Single form model for card/account creation and editing
- Bidirectional mapping: LedgerForm ↔ Ledger via init(from:) and toLedger()
- Equatable, Sendable for state machine and concurrency
- Replaces Ledger, TargetCreationState, CardEditFormState duplication
- Eliminates field-by-field manual mapping
- Used by CardEditView, ImportViewModel, all ledger workflows
```

---

### Task 2: Create CardEditViewModel

**File:** `Apps/FinanceOSMac/FinanceOSMac/Presentation/Cards/CardEditViewModel.swift` (new)

**Checklist:**
- [ ] Define CardEditViewModel class
- [ ] Add @MainActor decorator
- [ ] Properties (Observable):
  - [ ] form: LedgerForm
  - [ ] showDeleteConfirm: Bool
  - [ ] showCardSelection: Bool
  - [ ] isLoading: Bool
  - [ ] errorMessage: String?
- [ ] @ObservationIgnored properties:
  - [ ] ledgerRepository: LedgerRepository
  - [ ] cardDatabase: CardDatabase
  - [ ] deleteTask: Task<Void, Never>?
- [ ] Methods:
  - [ ] init(...)
  - [ ] loadForEdit(_ ledger: Ledger)
  - [ ] loadForCreation(prefill: LedgerForm?)
  - [ ] saveLedger(_ ledger: Ledger) async throws
  - [ ] deleteLedger(_ ledger: Ledger) async throws
  - [ ] cancelDelete()
- [ ] Test task cancellation

**Code Template:**
```swift
@MainActor
final class CardEditViewModel: Observable {
    @ObservationIgnored private let ledgerRepository: LedgerRepository
    @ObservationIgnored private let cardDatabase: CardDatabase
    @ObservationIgnored private var deleteTask: Task<Void, Never>?
    
    var form: LedgerForm = LedgerForm()
    var showDeleteConfirm = false
    var showCardSelection = false
    var isLoading = false
    var errorMessage: String?
    
    init(
        ledgerRepository: LedgerRepository,
        cardDatabase: CardDatabase
    ) {
        self.ledgerRepository = ledgerRepository
        self.cardDatabase = cardDatabase
    }
    
    func loadForEdit(_ ledger: Ledger) {
        form = LedgerForm(from: ledger)
    }
    
    func loadForCreation(prefill: LedgerForm?) {
        form = prefill ?? LedgerForm()
    }
    
    func saveLedger(_ ledger: Ledger) async throws {
        isLoading = true
        defer { isLoading = false }
        
        let updated = form.toLedger(id: ledger.id, bankId: ledger.bankId, kind: ledger.kind, existing: ledger)
        try await ledgerRepository.update(updated)
    }
    
    func deleteLedger(_ ledger: Ledger) async throws {
        deleteTask?.cancel()
        deleteTask = Task {
            try await ledgerRepository.delete(ledger.id)
        }
    }
}
```

**Commit Message:**
```
feat: Add CardEditViewModel, consolidate form state

- Owns LedgerForm, not Views
- @MainActor-isolated for thread safety
- Handles save, delete, async operations
- Task cancellation for delete operations
- Replaces scattered @State properties in CardEditView
- Central source of truth for card/account form state
```

---

### Task 3: Add @MainActor to Existing ViewModels

**Files (refactor):**
- `Apps/FinanceOSMac/FinanceOSMac/Presentation/Accounts/AccountsViewModel.swift`
- `Apps/FinanceOSMac/FinanceOSMac/Presentation/Cards/CardsViewModel.swift`
- `Apps/FinanceOSMac/FinanceOSMac/Presentation/Ledger/LedgerDetailViewModel.swift` (if exists)
- `Apps/FinanceOSMac/FinanceOSMac/Presentation/Transactions/TransactionsViewModel.swift`

**Checklist per ViewModel:**
- [ ] Add @MainActor to class declaration
- [ ] Verify all Observable properties are updated on MainThread
- [ ] Add @ObservationIgnored to all repository/service properties
- [ ] Identify any background thread operations (Task { }, DispatchQueue, etc.)
- [ ] Wrap state mutations with `await` if needed (compiler will enforce)
- [ ] Remove manual DispatchQueue.main.async wrappers (redundant with @MainActor)
- [ ] Test no MainThread warnings in debugger

**Example Refactor (AccountsViewModel):**
```swift
// BEFORE
class AccountsViewModel: Observable {
    var ledgers: [Ledger] = []
    var isLoading = false
    
    func loadLedgers() {
        Task {
            do {
                let loaded = try await ledgerRepository.fetchLedgers()
                DispatchQueue.main.async {  // REDUNDANT with @MainActor
                    self.ledgers = loaded
                }
            } catch { }
        }
    }
}

// AFTER
@MainActor
final class AccountsViewModel: Observable {
    var ledgers: [Ledger] = []
    var isLoading = false
    
    func loadLedgers() {
        Task {
            do {
                let loaded = try await ledgerRepository.fetchLedgers()
                self.ledgers = loaded  // Guaranteed on MainThread
            } catch { }
        }
    }
}
```

**Commit Message:**
```
refactor: Introduce @MainActor isolation to all ViewModels

- AccountsViewModel, CardsViewModel, TransactionsViewModel, LedgerDetailViewModel
- Guarantees all Observable property mutations on MainThread
- Removes redundant DispatchQueue.main.async wrappers
- Compiler enforces thread safety (no background thread property access)
- Prevents race conditions in concurrent load/refresh scenarios
```

---

## Sub-Phase 2B: Import State Machine Refactor (Days 9-12)

### Task 4: Refactor ImportViewModel

**File:** `Apps/FinanceOSMac/FinanceOSMac/Presentation/Import/ImportViewModel.swift` (refactor)

**Checklist:**
- [ ] Add @MainActor to class
- [ ] Replace fragmented state properties:
  - [ ] Remove isLoading, errorMessage, selectedSource
  - [ ] Remove showCardSelection, showDeleteConfirm
  - [ ] Add single flowState: ImportFlowState = .idle
- [ ] Add task management:
  - [ ] Add currentTask: Task<Void, Never>?
  - [ ] Add parsingTask: Task<Void, Never>?
- [ ] Refactor public methods:
  - [ ] loadTargetsOnAppear() → unchanged
  - [ ] selectSourceAndAdvance(_ source:)
  - [ ] selectFilesAndAdvance(_ fileURLs:) async
  - [ ] performImport(target:) async
  - [ ] cancelImport()
- [ ] Implement state transitions:
  - [ ] idle → selectingSource (selectSourceAndAdvance)
  - [ ] selectingSource → selectingFiles (user selects files)
  - [ ] selectingFiles → parsing (parseFiles)
  - [ ] parsing → review (detectDuplicates)
  - [ ] review → importing (performImport)
  - [ ] importing → completed/failed
- [ ] Add task cancellation:
  - [ ] Check Task.isCancelled in loops
  - [ ] Call task?.cancel() in cancel()
  - [ ] Handle CancellationError in catch blocks
- [ ] Write state machine tests (20+ tests covering all transitions)

**Code Template:**
```swift
@MainActor
final class ImportViewModel: Observable {
    @ObservationIgnored private let ledgerRepository: LedgerRepository
    @ObservationIgnored private let bankRepository: BankRepository
    @ObservationIgnored private let transactionRepository: TransactionRepository
    @ObservationIgnored private let transactionImportPipeline: TransactionImportPipeline
    @ObservationIgnored private let accountMatcher: ImportTargetMatcher
    @ObservationIgnored private var currentTask: Task<Void, Never>?
    
    var flowState: ImportFlowState = .idle
    var ledgers: [Ledger] = []
    var banks: [Banks] = []
    
    init(...) { ... }
    
    func loadTargetsOnAppear() async {
        do {
            async let ledgers = ledgerRepository.fetchLedgers()
            async let banks = bankRepository.fetchBanks()
            self.ledgers = try await ledgers
            self.banks = try await banks
        } catch {
            flowState = .failed(error: .importFailed(message: error.localizedDescription))
        }
    }
    
    func selectSourceAndAdvance(_ source: StatementSource) {
        flowState = .selectingFiles
    }
    
    func selectFilesAndAdvance(_ fileURLs: [URL]) async {
        flowState = .parsing(progress: 0)
        currentTask?.cancel()
        
        currentTask = Task {
            do {
                let statements = try await parseStatements(fileURLs)
                try Task.checkCancellation()
                
                await detectDuplicatesAndAutoSelect(statements)
                try Task.checkCancellation()
                
                flowState = .review(
                    statements: statements.map { ParsedStatementSnapshot(from: $0) },
                    target: .ledger(UUID()),
                    duplicateIndices: Set()
                )
            } catch is CancellationError {
                flowState = .idle
            } catch {
                flowState = .failed(error: .parseError(fileName: "unknown", underlying: error.localizedDescription))
            }
        }
    }
    
    func performImport(target: TransactionImportTarget) async {
        flowState = .importing(progress: ImportProgress(fileNumber: 1, totalFiles: 1, transactionsProcessed: 0, totalTransactions: 0))
        currentTask?.cancel()
        
        currentTask = Task {
            do {
                let result = try await importWithTransaction(target: target)
                try Task.checkCancellation()
                flowState = .completed(result: result)
            } catch is CancellationError {
                flowState = .idle
            } catch {
                flowState = .failed(error: .importFailed(message: error.localizedDescription))
            }
        }
    }
    
    func cancelImport() {
        guard flowState.canCancel else { return }
        currentTask?.cancel()
        currentTask = nil
        flowState = .idle
    }
    
    // MARK: - Private Helpers
    
    private func parseStatements(_ fileURLs: [URL]) async throws -> [ParsedStatement] {
        var statements: [ParsedStatement] = []
        for (index, url) in fileURLs.enumerated() {
            try Task.checkCancellation()
            flowState = .parsing(progress: Double(index) / Double(fileURLs.count))
            let statement = try await parseFile(url)
            statements.append(statement)
        }
        return statements
    }
    
    private func importWithTransaction(target: TransactionImportTarget) async throws -> ImportResult {
        // Implemented in Phase 3
    }
}
```

**Commit Message:**
```
refactor: Refactor ImportViewModel to use ImportFlowState, add task cancellation

- Replace fragmented state (isLoading, errorMessage, selectedSource) with ImportFlowState
- Single source of truth: flowState: ImportFlowState = .idle
- Task cancellation at parsing and importing states
- State transitions: idle → selectingSource → selectingFiles → parsing → review → importing → completed
- Guard state transitions via canCancel computed property
- CancellationError handling in all async blocks
- Structured concurrency with Task.checkCancellation()
```

---

### Task 5: Update CardEditView

**File:** `Apps/FinanceOSMac/FinanceOSMac/Presentation/Cards/CardEditView.swift` (refactor)

**Checklist:**
- [ ] Move form state to @Environment(CardEditViewModel.self)
- [ ] Keep only ephemeral UI state as @State:
  - [ ] showDeleteConfirm (presentation)
  - [ ] showCardSelection (sheet)
  - [ ] Other: focus, animations, temporary UI state only
- [ ] Bind form properties via $vm.form.nickname, etc.
- [ ] Update CardDisplayPreview to use vm.form
- [ ] Simplify headerBar, scrollContent, footerBar
- [ ] Remove manual state initialization
- [ ] Add .task { await vm.loadForEdit(...) } or .task { vm.loadForCreation(...) }

**Code Template:**
```swift
struct CardEditView: View {
    let mode: CardEditMode
    @Environment(\.dismiss) var dismiss
    @Environment(CardEditViewModel.self) var vm
    
    // ONLY ephemeral UI state
    @State private var showDeleteConfirm = false
    @State private var showCardSelection = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            headerBar
            Divider()
            scrollContent
            Divider().opacity(0.3)
            footerBar
        }
        .task {
            switch mode {
            case let .edit(ledger, _):
                vm.loadForEdit(ledger)
            case let .createCard(prefill, _):
                vm.loadForCreation(prefill: prefill)
            case let .createAccount(prefill, _):
                vm.loadForCreation(prefill: prefill)
            }
        }
    }
    
    private var basicInfoSurface: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("BASIC INFORMATION")
            
            TextField("Nickname", text: $vm.form.nickname)
            TextField("Cardholder Name", text: $vm.form.cardholderName)
            
            CardDisplayPreview(
                cardName: vm.cardDatabase.supportedCards().first { $0.id == vm.form.cardProductId?.rawValue }?.name,
                bankName: vm.form.selectedBank?.displayName,
                cardholderName: vm.form.cardholderName,
                cardNetwork: vm.form.cardType,
                first4: vm.form.first4,
                last4: vm.form.last4,
                bankLogo: vm.form.selectedBank?.logoAssetName
            )
        }
    }
}
```

**Commit Message:**
```
refactor: Update CardEditView to use CardEditViewModel

- Remove form state from View (@State properties)
- Move to CardEditViewModel (single source of truth)
- Bind form fields via $vm.form.* properties
- Keep only ephemeral UI state (showDeleteConfirm, showCardSelection)
- Simplify View to presentation only
- Add .task { vm.loadForEdit/loadForCreation } initialization
```

---

## Validation Checklist

Before moving to Phase 3:

- [ ] All 4 ViewModels @MainActor-isolated
- [ ] ImportViewModel fully refactored to use ImportFlowState
- [ ] CardEditViewModel created and integrated
- [ ] LedgerForm bidirectional mapping working
- [ ] CardEditView refactored to use CardEditViewModel
- [ ] All Ledger workflows using LedgerForm (no Ledger/TargetCreationState/CardEditFormState)
- [ ] State machine tests passing (20+ tests)
- [ ] Task cancellation working at parse and import states
- [ ] No lint violations (swiftlint lint)
- [ ] Code review sign-off

---

## Success Criteria

- [x] ImportFlowState replaces all fragmented state
- [x] All ViewModels @MainActor-isolated
- [x] 61 @State properties moved to ViewModels
- [x] Views contain only ephemeral state
- [x] Single source of truth per domain (LedgerForm)
- [x] Zero manual field-by-field mapping
- [x] Task cancellation working at all states


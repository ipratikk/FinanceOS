# Phase 4: Enforcement - Architectural Rules & Documentation

**Duration:** Days 18-20  
**Commits:** 2  
**Risk:** Low  
**Blocking:** None (final phase)  
**Depends On:** Phase 3 complete

---

## Overview

Enforce architectural rules via SwiftLint, update documentation, create migration guides, conduct final audit.

---

## Task 1: Add SwiftLint Rules for Architectural Enforcement

**Files to Create/Modify:**
- `.swiftlint.yml` (add custom rules)
- `Packages/FinanceCore/Sources/FinanceCore/.swiftlint-build.yml` (build target rules)
- `Apps/FinanceOSMac/FinanceOSMac/.swiftlint-ui.yml` (UI target rules)

**Checklist:**
- [ ] Add rule: Forbidden imports in Views (cannot import GRDB)
- [ ] Add rule: Forbidden imports in Models (cannot import SwiftUI)
- [ ] Add rule: Forbidden imports in Parsers (cannot import UI modules)
- [ ] Add rule: String-typed state detection (suggest enum instead)
- [ ] Add rule: UUID parameter detection (suggest typed ID wrapper)
- [ ] Add rule: MainActor ViewModel requirement
- [ ] Add rule: Sendable model requirement (with exceptions)
- [ ] Add rule: Line length max 120
- [ ] Add rule: Function body max 50 lines
- [ ] Add rule: Struct/type body max 250 lines
- [ ] Test all rules on existing codebase
- [ ] Document exceptions (documented list of allowed violations)

**Example .swiftlint.yml:**

```yaml
rules:
  - line_length:
      warning: 120
      error: 150
  - function_body_length:
      warning: 50
      error: 80
  - file_length:
      warning: 400
      error: 600

custom_rules:
  forbidden_grdb_in_views:
    name: "Forbidden GRDB import in Views"
    regex: '^(?!.*Tests).*View\.swift:.*import GRDB'
    message: "Views cannot import GRDB directly. Use repositories instead."
    severity: error
  
  forbidden_swiftui_in_models:
    name: "Forbidden SwiftUI import in Models"
    regex: '^(?!.*Tests).*Models/.*\.swift:.*import SwiftUI'
    message: "Models cannot import SwiftUI. Keep models UI-agnostic."
    severity: error
  
  forbidden_swiftui_in_parsers:
    name: "Forbidden SwiftUI import in Parsers"
    regex: '^(?!.*Tests).*Parsers/.*\.swift:.*import SwiftUI'
    message: "Parsers cannot import SwiftUI. Keep parsers UI-agnostic."
    severity: error
  
  uuid_parameter_not_typed:
    name: "UUID parameter should use typed ID wrapper"
    regex: 'func.*\(.*uuid: UUID'
    message: "Use typed ID (LedgerID, TransactionID) instead of raw UUID"
    severity: warning
  
  string_typed_state:
    name: "String-typed state should be enum"
    regex: '(var|let).*: String.*=.*(\"active\"|\"pending\"|\"completed\")'
    message: "Use enum instead of string-typed state (e.g., ImportStatus enum)"
    severity: warning
  
  viewmodel_not_mainactor:
    name: "ViewModel must be @MainActor"
    regex: '^(?!.*@MainActor).*ViewModel.*class'
    message: "All ViewModels must be @MainActor for thread safety"
    severity: error

excluded:
  - Packages/FinanceCore/Tests
  - Apps/FinanceOSMac/FinanceOSMacTests
```

**Commit Message:**
```
infra: Add SwiftLint rules for architectural enforcement

Adds custom SwiftLint rules to enforce architecture patterns:
- Forbidden GRDB in Views, SwiftUI in Models/Parsers
- UUID parameters should use typed ID wrappers
- String-typed state should be enums
- All ViewModels must be @MainActor

Enforces layer separation and type safety across codebase.
Prevents accidental architectural violations.
```

---

## Task 2: Update ARCHITECTURE.md

**File:** `ARCHITECTURE.md` (update)

**Checklist:**
- [ ] Add section: "State Management Architecture"
  - [ ] Diagram: View → ViewModel → Repository → GRDB → SQLite
  - [ ] Explain: Single source of truth principle
  - [ ] State ownership rules: Views have ephemeral state, VMs have persistent state
  - [ ] @MainActor isolation guarantee
- [ ] Add section: "Type Safety Patterns"
  - [ ] Typed ID wrappers: LedgerID, TransactionID, CardProductID
  - [ ] Enum-based state machines: ImportFlowState
  - [ ] Immutable snapshots: ParsedStatementSnapshot
  - [ ] Example: Converting UUID → LedgerID
- [ ] Add section: "Concurrency Model"
  - [ ] Structured concurrency: async let, Task { }
  - [ ] Task cancellation: currentTask?.cancel()
  - [ ] CancellationError handling
  - [ ] Sendable conformance
- [ ] Add section: "Workflow Coordinators"
  - [ ] ImportWorkflowCoordinator pattern
  - [ ] State transition guards
  - [ ] Navigation orchestration
- [ ] Add section: "Transactional Imports"
  - [ ] Single database transaction
  - [ ] Duplicate detection atomicity
  - [ ] Serialized execution
  - [ ] Rollback on error
- [ ] Add section: "Completed Phases" (update)
  - [ ] Phase 1: Type safety foundation (complete)
  - [ ] Phase 2: State management consolidation (complete)
  - [ ] Phase 3: Concurrency & workflows (complete)
  - [ ] Phase 4: Architectural enforcement (complete)
- [ ] Add section: "Future Work"
  - [ ] Aggregate domain models (LedgerAggregate, etc.)
  - [ ] Workflow coordinators for other domains (Transactions, Sync)
  - [ ] API layer (REST/GraphQL)

**Example Section:**

```markdown
## State Management Architecture

Views contain only ephemeral state (animations, focus, sheet presentation).
Persistent state lives in ViewModels (@MainActor-isolated).
Single source of truth per domain: Ledger, Transaction, ImportSession.

### State Ownership Rules

```
┌─────────────────┐
│   View          │  Ephemeral: @State<focus, animations, sheet>
│                 │
│ $vm.form.name ←─┼──→ ViewModel     Persistent: @Observable<form, isLoading>
│                 │                   @MainActor guarantee
└─────────────────┘
        ↓
┌─────────────────┐
│   Repository    │  Protocol-based, testable
│                 │  Encapsulates persistence
└─────────────────┘
        ↓
┌─────────────────┐
│   GRDB          │  SQL queries, migrations
│   DatabaseQueue │  Thread-bound, serialized access
└─────────────────┘
```

### MainActor Isolation

All ViewModels are @MainActor-isolated, guaranteeing:
- Property mutations always on MainThread
- No manual DispatchQueue.main.async needed
- Compiler enforces thread safety

## Type Safety Patterns

### Typed ID Wrappers

Instead of passing raw UUID:

```swift
// ❌ Don't: UUID can be confused for any ID
func deleteLedger(id: UUID) async throws

// ✅ Do: LedgerID is explicit
func deleteLedger(id: LedgerID) async throws

// Conversion
let ledger: Ledger
let ledgerId: LedgerID = ledger.id
```

### Enum-Based State Machines

Import workflow uses deterministic ImportFlowState:

```swift
enum ImportFlowState: Equatable {
    case idle
    case selectingSource
    case parsing(progress: Double)
    case review(statements, target, duplicates)
    case importing(progress: ImportProgress)
    case completed(result: ImportResult)
    case failed(error: ImportError)
    
    var canCancel: Bool {
        switch self {
        case .selectingSource, .selectingFiles, .parsing, .importing, .review: return true
        default: return false
        }
    }
}

// Impossible invalid states:
// Can't transition from idle → importing (compiler prevents)
// Can't have isLoading=false and currentStep=parsing (single ImportFlowState)
```

## Concurrency Model

### Structured Concurrency with async let

```swift
@MainActor
func loadDashboard() async {
    do {
        async let ledgers = ledgerRepository.fetchLedgers()
        async let banks = bankRepository.fetchBanks()
        
        self.ledgers = try await ledgers
        self.banks = try await banks
    } catch {
        errorMessage = error.localizedDescription
    }
}
```

### Task Cancellation

```swift
@MainActor
func cancelImport() {
    currentTask?.cancel()
    currentTask = nil
    flowState = .idle
}

// In async block
Task {
    do {
        try Task.checkCancellation()
        // Work...
    } catch is CancellationError {
        // Silently cancelled, clean up
    }
}
```

### Sendable Conformance

All models Sendable:
- Ledger, Transaction, CardMetadata
- LedgerForm, ParsedStatementSnapshot
- ImportFlowState, ImportError

Non-Sendable (documented exceptions):
- GRDB DatabaseQueue (thread-bound)
- ImportSession (mutable @ObservationIgnored, kept @MainActor)
```

**Commit Message:**
```
docs: Update ARCHITECTURE.md with state machines and typed ID patterns

Adds comprehensive documentation for production-grade architecture:
- State management layer diagram and ownership rules
- Type safety patterns (typed IDs, enums, snapshots)
- Concurrency model (structured concurrency, task cancellation, Sendable)
- Workflow coordinator patterns
- Transactional import boundaries
- Marks all 4 refactor phases complete
- Migration guides for future extensions
```

---

## Task 3: Create Migration Guides

**File:** `MIGRATION_GUIDE.md` (new)

**Checklist:**
- [ ] Section: "UUID → Typed ID Migration"
  - [ ] Converting old UUID parameters to LedgerID
  - [ ] Database loading (backward compatible init)
  - [ ] Codable encoding (encodes as UUID for compat)
- [ ] Section: "String State → Enum Migration"
  - [ ] Converting accountType: String to AccountType enum
  - [ ] DB migration (no schema changes)
  - [ ] Fallback values for unknown entries
- [ ] Section: "View State → ViewModel State Migration"
  - [ ] Moving @State to ViewModel (@Observable)
  - [ ] Binding syntax changes ($vm.form.nickname)
  - [ ] Ephemeral state that stays in View
- [ ] Section: "Adding New ViewModels"
  - [ ] Template for new @MainActor ViewModel
  - [ ] Observable property pattern
  - [ ] @ObservationIgnored for repositories
  - [ ] Task cancellation pattern
- [ ] Section: "Adding New State Machines"
  - [ ] Template for new workflow state enum
  - [ ] Impossible invalid states pattern
  - [ ] Computed guard properties (canTransition)
- [ ] Section: "Sendable Conformance"
  - [ ] Checklist for marking model Sendable
  - [ ] Identifying non-Sendable dependencies
  - [ ] Documentation pattern for exceptions

**Example Content:**

```markdown
# Migration Guide: FinanceOS Production-Grade Refactor

## UUID → Typed ID Migration

### Before (stringly-typed)
```swift
func deleteLedger(id: UUID) async throws {
    try await repository.deleteLedger(id)
}
```

### After (typed)
```swift
func deleteLedger(id: LedgerID) async throws {
    try await repository.deleteLedger(id)
}
```

### Migration Steps
1. Replace UUID with LedgerID in function signatures
2. Convert UUID values: `LedgerID(uuid)`
3. Access raw UUID: `ledgerId.rawValue`
4. Database layer unchanged (TypedID encodes as UUID)

## String State → Enum Migration

### Before (stringly-typed)
```swift
struct Ledger {
    var accountType: String?  // "savings", "checking", "other"
}
```

### After (type-safe)
```swift
struct Ledger {
    var accountType: AccountType?  // .savings, .checking, .other
}
```

### Migration Steps
1. Define AccountType enum with String rawValue
2. Update Ledger model
3. Update GRDB mapper: `accountType: String → AccountType.init(rawValue:)`
4. Fallback to .other for unknown values
5. No DB schema changes

## View State → ViewModel State Migration

### Before (View owns state)
```swift
struct CardEditView: View {
    @State var form: CardEditFormState  // 10 @State properties
    @State var showDeleteConfirm = false
    
    var body: some View {
        TextField("Nickname", text: $form.nickname)
    }
}
```

### After (ViewModel owns state)
```swift
@MainActor
final class CardEditViewModel: Observable {
    var form: LedgerForm = LedgerForm()  // Persistent
    // No @State here
}

struct CardEditView: View {
    @Environment(CardEditViewModel.self) var vm
    @State var showDeleteConfirm = false  // Only ephemeral
    
    var body: some View {
        TextField("Nickname", text: $vm.form.nickname)
    }
}
```

### Migration Checklist
- [ ] Create ViewModel class with @MainActor
- [ ] Move @State properties to @Observable properties
- [ ] Keep only ephemeral UI state as @State (focus, animations, sheet)
- [ ] Update bindings: `$form.field` → `$vm.form.field`
- [ ] Add .task { await vm.load(...) }

## Adding New Typed IDs

### Template
```swift
struct NewEntityID: Hashable, Codable, Sendable {
    let rawValue: UUID
    init(_ uuid: UUID) { self.rawValue = uuid }
}

// In model
struct NewEntity: Identifiable {
    let id: NewEntityID
}
```

## Adding New State Machines

### Template
```swift
enum WorkflowState: Equatable, Sendable {
    case idle
    case active(progress: Double)
    case completed(result: Result)
    case failed(error: Error)
    
    var canCancel: Bool {
        switch self {
        case .active: return true
        default: return false
        }
    }
}

// In ViewModel
@MainActor
final class WorkflowViewModel: Observable {
    var workflowState: WorkflowState = .idle
    var currentTask: Task<Void, Never>?
    
    func cancel() {
        currentTask?.cancel()
        workflowState = .idle
    }
}
```

## Sendable Conformance Checklist

- [ ] All model properties are Sendable (or documented exceptions)
- [ ] No mutable references in Sendable types
- [ ] Codable types can encode/decode Sendable values
- [ ] Mark with `struct Model: Sendable { ... }`
- [ ] Run compiler check: no Sendable warnings
```

**Commit Message:**
```
docs: Add MIGRATION_GUIDE.md for typed IDs, state enums, ViewModels

Comprehensive migration guide for:
- UUID → LedgerID conversion (backward compatible)
- String state → AccountType enum (no DB changes)
- View @State → ViewModel @Observable (persistent state ownership)
- Adding new ViewModels (@MainActor template)
- Adding new state machines (enum pattern)
- Sendable conformance checklist

Enables safe extensions and pattern replication across codebase.
```

---

## Task 4: Final Audit & Cleanup

**Checklist:**
- [ ] Run `swiftlint lint` across all files (should be zero violations)
- [ ] Run `swift -typecheck-only` (should be zero Sendable warnings)
- [ ] Run full test suite (all tests passing)
- [ ] Code review: Phase 1-4 all commits
  - [ ] Architectural consistency check
  - [ ] Thread safety review
  - [ ] Performance impact assessment
  - [ ] Documentation completeness
- [ ] Update CHANGELOG.md with refactor summary
- [ ] Verify no regressions in existing functionality
- [ ] Create refactor retrospective (lessons learned)

**Code Review Checklist:**

```
Phase 1: Type Safety Foundation
- [ ] TypedIDs encode/decode correctly
- [ ] AccountType enum backward compatible
- [ ] Ledger loads from old DB schema
- [ ] ImportFlowState impossible invalid states

Phase 2: State Management
- [ ] LedgerForm bidirectional mapping working
- [ ] All ViewModels @MainActor-isolated
- [ ] Views contain only ephemeral state
- [ ] CardEditViewModel integrated correctly
- [ ] ImportViewModel state machine transitions working

Phase 3: Concurrency & Workflows
- [ ] All models Sendable
- [ ] Structured concurrency (async let, not Task)
- [ ] Task cancellation in all VMs
- [ ] ImportWorkflowCoordinator state transitions
- [ ] Multi-file imports atomic (no partial inserts)
- [ ] Concurrent imports serialized

Phase 4: Enforcement
- [ ] SwiftLint custom rules enforcing architecture
- [ ] ARCHITECTURE.md updated with diagrams
- [ ] MIGRATION_GUIDE.md complete
- [ ] Zero lint violations
- [ ] Zero Sendable warnings
- [ ] All tests passing
```

**Commit Message:**
```
refactor: Final audit and cleanup - Production-grade refactor complete

- All SwiftLint custom rules enforcing architecture
- Zero lint violations (swiftlint lint)
- Zero Sendable compiler warnings
- All tests passing (unit, integration, snapshot)
- ARCHITECTURE.md updated with state machines, typed IDs, concurrency
- MIGRATION_GUIDE.md complete for future extensions
- No regressions in existing functionality
- Code review sign-off

Production-grade FinanceOS refactor complete:
✓ Type safety (typed IDs, enums)
✓ State management (single source of truth, MainActor)
✓ Concurrency (structured concurrency, Sendable)
✓ Workflows (coordinators, transactional imports)
✓ Architectural enforcement (SwiftLint rules)
```

---

## Validation Checklist

Before considering refactor complete:

- [ ] All 4 phases committed and merged
- [ ] Zero swiftlint violations (`swiftlint lint`)
- [ ] Zero Sendable compiler warnings
- [ ] All unit tests passing
- [ ] All integration tests passing
- [ ] All snapshot tests passing
- [ ] No regressions in existing functionality
- [ ] ARCHITECTURE.md fully updated
- [ ] MIGRATION_GUIDE.md complete
- [ ] Code review sign-off from team lead
- [ ] Performance metrics baseline established
- [ ] Metrics post-refactor match or improve baseline

---

## Success Criteria

- [x] SwiftLint rules enforcing architecture
- [x] Zero lint violations
- [x] ARCHITECTURE.md complete with diagrams
- [x] MIGRATION_GUIDE.md enables safe extensions
- [x] No regressions
- [x] All tests passing
- [x] Production-ready code quality

---

## Retrospective Template

```markdown
# Refactor Retrospective

## What Went Well
- [ ] Type safety foundation solid
- [ ] State machine pattern prevents bugs
- [ ] Task cancellation improves UX
- [ ] Sendable/MainActor catches race conditions early
- [ ] Documentation enables team scaling

## What Could Improve
- [ ] SwiftLint rule development (time-consuming)
- [ ] Transactional import complexity (required careful testing)
- [ ] State machine testing (many edge cases)

## Metrics
- Lines of code changed: X
- New test coverage: Y%
- Performance impact: Z% (baseline vs post-refactor)
- Build time change: ±A%

## Lessons Learned
1. Typed IDs prevent entire classes of bugs
2. MainActor isolation is worth the ergonomic cost
3. State machines make code crystal clear
4. Comprehensive testing catches architectural issues early

## Next Steps
1. Monitor metrics in production
2. Gather team feedback
3. Plan P2 (aggregate models, more coordinators)
```


# Phase 1: Foundation - Type Safety & Deterministic State

**Duration:** Days 1-5  
**Commits:** 5  
**Risk:** Low  
**Blocking:** Phase 2, Phase 3

---

## Overview

Establish type-safe foundation: replace String identifiers with typed wrappers, introduce enum-based state machines, create immutable snapshots. Zero behavioral changes, pure encoding layer.

---

## Task 1: Create TypedIDs.swift

**File:** `Packages/FinanceCore/Sources/FinanceCore/Types/TypedIDs.swift` (new)

**Checklist:**
- [ ] Define LedgerID (wraps UUID)
- [ ] Define TransactionID (wraps UUID)
- [ ] Define ImportSessionID (wraps UUID)
- [ ] Define StatementID (wraps UUID)
- [ ] Define CardProductID (wraps String)
- [ ] Make all Hashable, Codable, Sendable
- [ ] Add init helpers for UUID → LedgerID conversions
- [ ] Add rawValue getter for backward compat
- [ ] Write unit tests (encoding/decoding, equality, hashing)
- [ ] Verify builds, no compilation errors

**Code Template:**
```swift
struct LedgerID: Hashable, Codable, Sendable {
    let rawValue: UUID
    init(_ uuid: UUID) { self.rawValue = uuid }
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.rawValue = try container.decode(UUID.self)
    }
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}
```

**Commit Message:**
```
feat: Add typed ID wrappers (LedgerID, TransactionID, ImportSessionID, CardProductID)

- Replaces stringly-typed UUID/String with compiler-enforced type wrappers
- Backward-compatible Codable encoding (encodes as base UUID/String)
- Sendable for concurrency safety
- Prevents accidental UUID/LedgerID conversions
- Includes unit tests for encoding, equality, hashing
```

---

## Task 2: Create AccountType.swift

**File:** `Packages/FinanceCore/Sources/FinanceCore/Types/AccountType.swift` (new)

**Checklist:**
- [ ] Define AccountType enum (savings, checking, moneyMarket, other)
- [ ] Add rawValue for DB persistence
- [ ] Add displayName computed property
- [ ] Make Codable, Sendable
- [ ] Handle unknown values (fallback to .other)
- [ ] Write unit tests (init from string, displayName, encoding)

**Code Template:**
```swift
enum AccountType: String, Codable, Sendable {
    case savings = "savings"
    case checking = "checking"
    case moneyMarket = "money_market"
    case other = "other"
    
    var displayName: String {
        switch self {
        case .savings: "Savings Account"
        case .checking: "Checking Account"
        case .moneyMarket: "Money Market Account"
        case .other: "Other"
        }
    }
}
```

**Commit Message:**
```
feat: Add AccountType enum, replace stringly-typed accountType: String

- Introduces type-safe AccountType enum (savings, checking, moneyMarket, other)
- Replaces Ledger.accountType: String? → AccountType?
- Backward-compatible String RawValue for DB persistence
- Includes displayName computed property for UI
- Fallback to .other for unknown values
```

---

## Task 3: Update Ledger Model

**File:** `Packages/FinanceCore/Sources/FinanceCore/Models/Ledger.swift` (refactor)

**Checklist:**
- [ ] Replace `id: UUID` with `id: LedgerID`
- [ ] Replace `accountType: String?` with `accountType: AccountType?`
- [ ] Replace `cardProductId: String?` with `cardProductId: CardProductID?`
- [ ] Replace `linkedLedgerId: UUID?` with `linkedLedgerId: LedgerID?`
- [ ] Update Codable conformance (use helper init)
- [ ] Add backward-compatible init(from decoder:) for DB loading
- [ ] Update all computed properties
- [ ] Write migration tests (old DB → new model)
- [ ] Test GRDB decoding with old schema

**Code Template:**
```swift
struct Ledger: Identifiable, Codable, Sendable {
    let id: LedgerID
    let bankId: UUID
    let kind: LedgerKind
    let displayName: String
    let last4: String
    let nickname: String
    let ownerName: String
    let createdAt: Date
    let accountType: AccountType?
    let cardType: CardNetwork?
    let cardProductId: CardProductID?
    let bin: String?
    let linkedLedgerId: LedgerID?
    let isArchived: Bool
    let closingBalance: Int64?
    let closingBalanceAsOf: Date?
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // UUID → LedgerID conversion
        let uuid = try container.decode(UUID.self, forKey: .id)
        self.id = LedgerID(uuid)
        
        // String → CardProductID conversion
        if let cardProdStr = try container.decodeIfPresent(String.self, forKey: .cardProductId) {
            self.cardProductId = CardProductID(cardProdStr)
        } else {
            self.cardProductId = nil
        }
        
        // Rest of decoding...
    }
}
```

**Commit Message:**
```
refactor: Update Ledger model to use typed IDs and AccountType enum

- Ledger.id: UUID → LedgerID (compiler-enforced type safety)
- Ledger.accountType: String? → AccountType? (type-safe account types)
- Ledger.cardProductId: String? → CardProductID? (typed wrapper)
- Ledger.linkedLedgerId: UUID? → LedgerID? (typed wrapper)
- Backward-compatible Codable (decodes old UUID/String values)
- Updated GRDB mappers for typed ID conversion
- Updated all affected repositories and services
```

---

## Task 4: Create ImportFlowState.swift

**File:** `Packages/FinanceCore/Sources/FinanceCore/Services/ImportFlowState.swift` (new)

**Checklist:**
- [ ] Define ImportFlowState enum with all states
  - [ ] idle
  - [ ] selectingSource
  - [ ] selectingFiles
  - [ ] parsing(progress: Double)
  - [ ] review(statements, target, duplicateIndices)
  - [ ] importing(progress: ImportProgress)
  - [ ] completed(result: ImportResult)
  - [ ] failed(error: ImportError)
- [ ] Define ImportProgress struct (fileNumber, totalFiles, transactionsProcessed, totalTransactions)
- [ ] Add overallProgress computed property
- [ ] Define ImportError enum (noFilesSelected, parseError, targetNotSelected, importFailed, cancelled)
- [ ] Add isInProgress computed property
- [ ] Add canCancel computed property
- [ ] Make Equatable, Sendable
- [ ] Write unit tests (state transitions, computed properties)

**Code Template:**
```swift
enum ImportFlowState: Equatable, Sendable {
    case idle
    case selectingSource
    case selectingFiles
    case parsing(progress: Double)
    case review(
        statements: [ParsedStatementSnapshot],
        target: TransactionImportTarget,
        duplicateIndices: Set<Int>
    )
    case importing(progress: ImportProgress)
    case completed(result: ImportResult)
    case failed(error: ImportError)
    
    var isInProgress: Bool {
        switch self {
        case .parsing, .importing: return true
        default: return false
        }
    }
    
    var canCancel: Bool {
        switch self {
        case .selectingSource, .selectingFiles, .parsing, .importing, .review: return true
        default: return false
        }
    }
}
```

**Commit Message:**
```
feat: Add ImportFlowState enum for deterministic import workflows

- Replaces fragmented ImportSession state with single ImportFlowState
- States: idle, selectingSource, selectingFiles, parsing, review, importing, completed, failed
- ImportProgress tracks multi-file import progress
- ImportError enum consolidates error cases
- Computed properties: isInProgress, canCancel (guards state transitions)
- Equatable, Sendable for MainActor usage
- Impossible invalid states (compiler-enforced state machine)
```

---

## Task 5: Create Immutable Snapshots

**File:** `Packages/FinanceCore/Sources/FinanceCore/Models/ParsedStatementSnapshot.swift` (new)

**Checklist:**
- [ ] Define ParsedStatementSnapshot struct (let properties only)
  - [ ] id: StatementID
  - [ ] metadata: ParsedMetadata?
  - [ ] transactions: [ParsedTransactionSnapshot]
  - [ ] sourceFileName: String
  - [ ] importedAt: Date
- [ ] Define ParsedTransactionSnapshot struct (let properties only)
  - [ ] id: String
  - [ ] postedAt: Date
  - [ ] description: String
  - [ ] amountMinorUnits: Int64
  - [ ] transactionType: TransactionType
  - [ ] category: String?
- [ ] Make both Hashable, Equatable, Sendable
- [ ] Add init from ParsedStatement (one-way conversion)
- [ ] Add init from ParsedTransaction (one-way conversion)
- [ ] Document immutability guarantee (compiler enforced)
- [ ] Write unit tests (equality, hashing, snapshot comparison)

**Code Template:**
```swift
struct ParsedStatementSnapshot: Hashable, Equatable, Sendable {
    let id: StatementID
    let metadata: ParsedMetadata?
    let transactions: [ParsedTransactionSnapshot]
    let sourceFileName: String
    let importedAt: Date
    
    init(from statement: ParsedStatement) {
        self.id = StatementID(UUID())
        self.metadata = statement.metadata
        self.transactions = statement.transactions.map(ParsedTransactionSnapshot.init)
        self.sourceFileName = statement.metadata?.filename ?? "unknown"
        self.importedAt = Date()
    }
    
    // Guarantee: never mutated after creation
    // Compiler enforces via `let` properties and Struct value semantics
}
```

**Commit Message:**
```
feat: Add immutable snapshots (ParsedStatementSnapshot, ParsedTransactionSnapshot)

- Immutable snapshots for import flows (all let properties)
- Snapshot ≠ mutable source (ParsedStatement) → one-way conversion
- Hashable, Equatable, Sendable for import state machines
- Compiler enforces immutability via value semantics
- Used in ImportFlowState.review() for deterministic state
- Prevents accidental mutation during import flow
```

---

## Validation Checklist

Before moving to Phase 2:

- [ ] All 5 new files compile without errors
- [ ] All GRDB mappers updated to use typed IDs
- [ ] TypedID unit tests pass (encoding/decoding/equality)
- [ ] AccountType unit tests pass
- [ ] ImportFlowState unit tests pass (state transitions)
- [ ] Snapshot unit tests pass (equality, hashing)
- [ ] Ledger loads from existing DB (backward-compatible)
- [ ] No lint violations (swiftlint lint)
- [ ] Code review sign-off

---

## Database Compatibility

**Schema:** No changes (String/UUID columns remain)  
**Mapping Layer:** TypedIDs encode as base types (UUID/String)  
**Backward Compat:** Old code reading new TypedID models works via Codable init  
**Forward Compat:** New code reading old UUID/String works via init helpers

**Example GRDB Mapper:**
```swift
extension Ledger {
    static func from(row: Row) throws -> Ledger {
        let uuid = try row.decode(UUID.self, forKey: "id")
        let cardProdStr = try row.decodeIfPresent(String.self, forKey: "cardProductId")
        let accountTypeStr = try row.decodeIfPresent(String.self, forKey: "accountType")
        
        return Ledger(
            id: LedgerID(uuid),
            // ...
            accountType: accountTypeStr.flatMap(AccountType.init),
            cardProductId: cardProdStr.map(CardProductID.init),
            // ...
        )
    }
}
```

---

## Success Criteria

- [x] Type safety foundation in place
- [x] Zero breaking changes to existing code
- [x] All new types Sendable
- [x] Backward-compatible DB loading
- [x] Compiler enforces typed ID usage
- [x] All unit tests passing
- [x] Zero lint violations


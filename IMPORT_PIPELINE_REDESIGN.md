# Import Pipeline Redesign — Phase 2

## Architecture Overview

### Current State Fragmentation
```
ImportViewModel                    ImportPreviewView @State
├── selectedSource                 ├── newEntityName
├── parsedStatements              ├── newEntityLast4
├── selectedTarget                ├── newEntityBankID
├── ledgers                        ├── newEntityOwnerName
└── banks                          ├── detectedBank
                                   └── isCard
```

**Problem**: State lives in 2 places. No single source of truth. selectedSource lost.

---

## New Architecture: ImportSession

### Design Goal
Single canonical object that owns all import state from file selection through final import.

```swift
@Observable
final class ImportSession: Sendable {
    // Parse phase
    var selectedSource: StatementSource?
    var fileURLs: [URL] = []
    var parsedStatements: [ParsedStatement] = []
    
    // Preview phase
    var matchedLedgers: [UUID: Ledger] = [:]  // last4 → existing ledger
    
    // Target creation phase
    var targetBeingCreated: TargetCreationState?
    
    // Final import
    var selectedTarget: TransactionImportTarget?
    var importResult: ImportResult?
    
    // Error handling
    var errorMessage: String?
    var isLoading = false
    
    // Derived state
    var currentParsedStatement: ParsedStatement? { parsedStatements.first }
    var isAccountType: Bool { currentParsedStatement?.cardLast4 == nil }
    var isCardType: Bool { !isAccountType }
}
```

---

## Extended Metadata Model

### Problem
StatementMetadata missing: customerName, accountType, fullAccountNumber.

### Solution: Enhance ParsedStatementMetadata

**In FinanceParsers/Models:**

```swift
// ParsedStatementMetadata.swift (NEW)
public struct ParsedStatementMetadata: Codable, Sendable, Equatable {
    /// Account holder name from statement
    public let accountHolderName: String?
    
    /// Full account/card number (if available)
    public let fullAccountNumber: String?
    
    /// Inferred from statement structure (bankAccount, creditCard, loan, etc)
    public let ledgerKind: LedgerKind?
    
    /// Inferred account type (savings, current, checking, etc)
    public let accountType: String?
    
    /// Inferred card type (visa, mastercard, amex, etc)
    public let cardType: String?
    
    /// Statement period start date
    public let statementPeriodStart: Date?
    
    /// Statement period end date
    public let statementPeriodEnd: Date?
    
    /// Currency code (INR, USD, etc)
    public let currency: String
    
    /// Total debit amount in minor units
    public let totalDebit: Int64
    
    /// Total credit amount in minor units
    public let totalCredit: Int64
    
    /// Parsed transactions
    public let parsedTransactions: [ParsedTransaction]
    
    public init(
        accountHolderName: String? = nil,
        fullAccountNumber: String? = nil,
        ledgerKind: LedgerKind? = nil,
        accountType: String? = nil,
        cardType: String? = nil,
        statementPeriodStart: Date? = nil,
        statementPeriodEnd: Date? = nil,
        currency: String = "INR",
        totalDebit: Int64 = 0,
        totalCredit: Int64 = 0,
        parsedTransactions: [ParsedTransaction] = []
    ) {
        self.accountHolderName = accountHolderName
        self.fullAccountNumber = fullAccountNumber
        self.ledgerKind = ledgerKind
        self.accountType = accountType
        self.cardType = cardType
        self.statementPeriodStart = statementPeriodStart
        self.statementPeriodEnd = statementPeriodEnd
        self.currency = currency
        self.totalDebit = totalDebit
        self.totalCredit = totalCredit
        self.parsedTransactions = parsedTransactions
    }
}
```

**Update ParsedStatement:**

```swift
public struct ParsedStatement: Codable, Sendable, Equatable {
    public let bankName: String
    public let accountName: String
    public let accountLast4: String?
    public let cardLast4: String?
    public let statementPeriodStart: Date?
    public let statementPeriodEnd: Date?
    public let currency: String
    public let totalDebit: Int64
    public let totalCredit: Int64
    public let transactions: [ParsedTransaction]
    
    // NEW: Single unified metadata
    public let metadata: ParsedStatementMetadata?
    
    // Derived properties for backward compatibility
    public var isCard: Bool {
        cardLast4 != nil
    }
    
    public var detectedLedgerKind: LedgerKind {
        metadata?.ledgerKind ?? (isCard ? .creditCard : .bankAccount)
    }
}
```

---

## Target Creation State

```swift
struct TargetCreationState: Sendable {
    /// Form field: custom name user entered
    var customName: String = ""
    
    /// Form field: nickname (cards only)
    var nickname: String = ""
    
    /// Form field: last 4 digits
    var last4: String = ""
    
    /// Form field: owner name (accounts only)
    var ownerName: String = ""
    
    /// Form field: selected bank ID
    var selectedBankID: UUID?
    
    /// True if creating card, false if account
    var isCard: Bool = false
    
    /// Account type (savings, current, etc) - for accounts only
    var accountType: String = "savings"
    
    /// Card type (visa, mastercard, etc) - for cards only
    var cardType: String = "other"
    
    /// Initialize from parsed statement (prefill values)
    mutating func initializeFromStatement(_ statement: ParsedStatement) {
        // Prefill last4
        last4 = isCard ? (statement.cardLast4 ?? "") : (statement.accountLast4 ?? "")
        
        // Prefill owner name from metadata
        ownerName = statement.metadata?.accountHolderName ?? ""
        
        // Prefill account/card type from metadata
        if isCard {
            cardType = statement.metadata?.cardType ?? "other"
        } else {
            accountType = statement.metadata?.accountType ?? "savings"
        }
        
        // Construct display name
        let displayName = statement.accountName.isEmpty ? statement.bankName : statement.accountName
        customName = !last4.isEmpty
            ? "\(displayName) •••• \(last4)"
            : displayName
    }
}
```

---

## Account Matcher Service

**Problem**: Currently uses fragile fuzzy matching. User's original selectedSource is lost.

**Solution**: New AccountMatcher service with fallback strategy.

```swift
// In FinanceCore (new file: Services/AccountMatcher.swift)

@MainActor
final class AccountMatcher: Sendable {
    private let ledgerRepository: any LedgerRepository
    private let bankRepository: any BankRepository
    
    init(
        ledgerRepository: any LedgerRepository,
        bankRepository: any BankRepository
    ) {
        self.ledgerRepository = ledgerRepository
        self.bankRepository = bankRepository
    }
    
    /// Match existing ledgers against parsed statement.
    /// Returns matched ledger and suggested bank.
    func findMatches(
        for statement: ParsedStatement
    ) async throws -> AccountMatchResult {
        let ledgers = try await ledgerRepository.fetchLedgers()
        let banks = try await bankRepository.fetchBanks()
        
        // Determine what we're looking for
        let lookingForCard = statement.isCard
        let targetLast4 = statement.cardLast4 ?? statement.accountLast4
        let targetBankName = statement.bankName
        
        // Strategy 1: Exact match (same bank + same last4 + same type)
        if let exactMatch = findExactMatch(
            ledgers: ledgers,
            bankName: targetBankName,
            last4: targetLast4,
            isCard: lookingForCard
        ) {
            return .exactMatch(exactMatch)
        }
        
        // Strategy 2: Fuzzy bank name + last4 match
        if let fuzzyMatch = findFuzzyMatch(
            ledgers: ledgers,
            bankName: targetBankName,
            last4: targetLast4,
            isCard: lookingForCard
        ) {
            return .fuzzyMatch(fuzzyMatch)
        }
        
        // Strategy 3: Find bank for account creation
        let suggestedBank = findOrCreateBank(
            name: targetBankName,
            from: banks
        )
        
        return .noMatch(suggestedBank: suggestedBank)
    }
    
    private func findExactMatch(
        ledgers: [Ledger],
        bankName: String,
        last4: String?,
        isCard: Bool
    ) -> Ledger? {
        guard let last4 else { return nil }
        
        return ledgers.first { ledger in
            ledger.kind == (isCard ? .creditCard : .bankAccount) &&
            ledger.last4 == last4 &&
            ledger.bankId != nil  // Has associated bank
        }
    }
    
    private func findFuzzyMatch(
        ledgers: [Ledger],
        bankName: String,
        last4: String?,
        isCard: Bool
    ) -> Ledger? {
        guard let last4 else { return nil }
        
        return ledgers.first { ledger in
            ledger.kind == (isCard ? .creditCard : .bankAccount) &&
            ledger.last4 == last4
            // Ignore bank name mismatch (fuzzy match on last4 alone)
        }
    }
    
    private func findOrCreateBank(
        name: String,
        from banks: [Bank]
    ) -> Bank? {
        // Exact match
        if let exact = banks.first(where: { $0.name == name }) {
            return exact
        }
        // Fuzzy match
        if let fuzzy = banks.first(where: { ImportFormatting.fuzzyMatch($0.name, name) }) {
            return fuzzy
        }
        // No match — bank will be created during ledger creation
        return nil
    }
    
    enum AccountMatchResult: Sendable {
        case exactMatch(Ledger)
        case fuzzyMatch(Ledger)
        case noMatch(suggestedBank: Bank?)
    }
}
```

---

## State Threading: Complete Flow

### File Selection Phase
```
ImportView.fileSelectionView
  ↓ @State selectedSource: StatementSource?
  ↓ onChange { viewModel.setSource(selectedSource) }
ImportViewModel
  ↓ importSession.selectedSource = source
  ↓ importSession.fileURLs = []
  ↓ importSession.parsedStatements = []
```

### Parsing Phase
```
ImportView.fileSelectionView
  ↓ DropZoneView / FilePicker
  ↓ viewModel.setFileURLs([url])
ImportViewModel.parseFiles()
  ↓ importSession.isLoading = true
  ↓ for url in importSession.fileURLs
    ↓ parseFile(url)
    ↓ importSession.parsedStatements.append(statement)
  ↓ await autoSelectMatchingTarget()
  ↓ importSession.isLoading = false
```

### Preview Phase
```
ImportView.previewView
  ↓ ImportPreviewView(session: importSession)
    → displays importSession.parsedStatements
    → displays importSession.matchedLedgers
    → allows target selection
```

### Target Creation Phase
```
ImportPreviewView.targetSelectionSection
  ↓ Button("Create New Account")
  ↓ initializeTargetCreation()
    → importSession.targetBeingCreated = TargetCreationState()
    → importSession.targetBeingCreated?.initializeFromStatement(statement)
    → show CreateNewTargetSheet
    
CreateNewTargetSheet(session: importSession)
  ↓ Binds to importSession.targetBeingCreated!.customName
  ↓ Binds to importSession.targetBeingCreated!.last4
  ↓ Binds to importSession.targetBeingCreated!.selectedBankID
  ↓ Button("Create")
    → await viewModel.createTarget(from: importSession)
```

### Import Phase
```
ImportPreviewView
  ↓ Button("Import")
  ↓ viewModel.importTransactions(session: importSession)
  ↓ importSession.importResult = result
  ↓ clear importSession or reset
```

---

## Key Design Decisions

### Decision 1: ImportSession in ViewModel, not View
```
WHY NOT in @State ImportPreviewView?
- Would reset on view rebuild
- Hard to pass to nested sheets
- ViewModel manages import logic anyway

INSTEAD: @Observable in ViewModel, passed via constructor
ImportPreviewView(session: viewModel.importSession)
```

### Decision 2: Metadata in FinanceParsers, not UI
```
WHY not define ParsedStatementMetadata in UI layer?
- Parsers produce it
- Serialization needs it in FinanceParsers
- UI just consumes it

RESULT: Define in FinanceParsers, import into FinanceCore
```

### Decision 3: TargetCreationState separate from ImportSession
```
WHY not merge into ImportSession?
- Only needed during account creation phase
- Cleaner separation of concerns
- Easier to test form state independently

RESULT: ImportSession.targetBeingCreated: TargetCreationState?
```

### Decision 4: selectedSource preserved through entire session
```
WHY store it?
- User's explicit choice, not inferred
- Used for parser selection
- Should inform bank selection in form
- Not lost on re-parsing

RESULT: importSession.selectedSource always available
```

### Decision 5: Automatic account matching BEFORE form shows
```
WHY run matcher before showing form?
- If exact match exists, auto-select it
- Show "Matched: HDFC •••• 1234"
- User rarely needs to create if match exists

FLOW:
1. Parse statement
2. Run AccountMatcher
3. If match: set importSession.selectedTarget = .ledger(matchedId)
4. Show preview without create sheet
5. If no match: show create sheet with prefilled metadata
```

---

## File Organization

### Changes to Existing Files

**FinanceParsers:**
```
Sources/FinanceParsers/Models/
├── ParsedStatement.swift (update)
├── ParsedStatementMetadata.swift (new)
└── ParsedTransaction.swift
```

**FinanceCore:**
```
Packages/FinanceCore/Sources/FinanceCore/
├── Models/
│   └── Ledger.swift (no change)
├── Repositories/
│   └── ...existing repos...
├── Services/ (new)
│   ├── AccountMatcher.swift (new)
│   └── ImportSession.swift (new)
└── Importing/
    └── ...existing import pipeline...
```

**FinanceOSMac:**
```
Apps/FinanceOSMac/FinanceOSMac/Presentation/Import/
├── ImportViewModel.swift (refactor)
├── ImportPreviewView.swift (refactor)
├── CreateNewTargetSheet.swift (refactor)
└── ImportViewModelTargetCreation.swift (refactor)
```

---

## Migration Strategy

### Phase 3a: Add New Models (Non-Breaking)
1. Create ParsedStatementMetadata in FinanceParsers
2. Update ParsedStatement to include metadata
3. Update parsers to populate new metadata fields
4. Keep old fields for backward compat

### Phase 3b: Add ImportSession (Non-Breaking)
1. Create ImportSession in FinanceCore.Services
2. Create AccountMatcher in FinanceCore.Services
3. Update ImportViewModel to use ImportSession
4. Pass ImportSession to views via constructor

### Phase 3c: Refactor Views (Breaking UI, Not Data)
1. Update ImportPreviewView to use ImportSession
2. Update CreateNewTargetSheet to use ImportSession bindings
3. Remove @State variables, use ImportSession instead

### Phase 3d: Update ViewModels (Internal Refactor)
1. Update createTargetFromDetected to use ImportSession
2. Remove redundant state from ImportViewModel
3. Add AccountMatcher usage to autoSelectMatchingTarget

---

## Benefits of New Architecture

| Problem | Current | New |
|---------|---------|-----|
| Bank selection lost | ❌ selectedSource not passed | ✅ Preserved in ImportSession |
| Last4 not prefilled | ❌ Depends on form initialization | ✅ Read from ParsedStatementMetadata |
| Owner name not prefilled | ❌ Missing from metadata | ✅ In ParsedStatementMetadata.accountHolderName |
| State fragmentation | ❌ Split between ViewModel + View | ✅ Single ImportSession |
| Manual account matching | ❌ User must select | ✅ Automatic via AccountMatcher |
| Metadata incomplete | ❌ StatementMetadata minimal | ✅ ParsedStatementMetadata comprehensive |
| Hard to test | ❌ State in @State, hard to mock | ✅ ImportSession @Observable, easy to test |
| State reset on rebuild | ❌ @State vars reset | ✅ ImportSession in ViewModel, persists |

---

## Testing Strategy

### Unit Tests
```swift
// AccountMatcher tests
func testExactMatch() // Same bank, same last4, same type
func testFuzzyMatch() // Same last4, different bank name
func testNoMatch() // No matching ledger

// TargetCreationState tests
func testInitializeFromStatement_Account()
func testInitializeFromStatement_Card()
```

### Integration Tests
```swift
// Full import flow tests
func testImportFlow_ExactMatch() // File → Parse → Match → Select → Import
func testImportFlow_CreateNew() // File → Parse → Create → Import
func testImportFlow_NoMatch() // File → Parse → No match → Create → Import
```

### UI Tests
```swift
// CreateNewTargetSheet tests
func testSheetPrefilled_WithStatement()
func testSheetEmpty_WithoutStatement()
func testBankSelection_FuzzyMatch()
func testBankSelection_ExactMatch()
```

---

## Rollout Plan

1. **Week 1**: Add models + AccountMatcher (review + merge)
2. **Week 2**: Add ImportSession (review + merge)
3. **Week 3**: Refactor views (review + merge)
4. **Week 4**: Update view models (review + merge)
5. **Week 5**: Testing + bugfixes
6. **Week 6**: Documentation + release

---

## Next: Phase 3 Implementation

Ready to implement:
1. ParsedStatementMetadata (FinanceParsers)
2. ImportSession (FinanceCore)
3. AccountMatcher (FinanceCore)
4. View refactors (FinanceOSMac)
5. ViewModel refactors (FinanceOSMac)


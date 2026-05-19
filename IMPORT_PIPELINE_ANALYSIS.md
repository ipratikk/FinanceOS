# Import Pipeline Architectural Analysis

## Executive Summary

Import flow is **structurally sound but fragmented**. Metadata exists in parsers but is **not systematically threaded** through UI layers. Result: users see empty forms despite successful parsing.

Root cause: No unified **ImportSession** object. Metadata flows via scattered bindings instead of single canonical state.

---

## Current Flow Trace

### 1. File Selection → Source Selection
```
ImportView.fileSelectionView
  ↓ selectedSource: StatementSource?
  ↓ (user selects HDFC Bank)
ImportViewModel.setSource(newValue)
  → selectedSource = StatementSource
  → clears fileURLs, parsedStatements, errorMessage
```

**Issue**: selectedSource is transient @State. Not passed to downstream views.

---

### 2. File Selection → Parsing

```
ImportView.filePickerButton / DropZoneView
  ↓ viewModel.setFileURLs(_:)
ImportViewModel.parseFiles()
  ↓ for fileURL in fileURLs
  ↓ parseFile(fileURL)
    → StatementDetector.detect() 
    → UnifiedStatementParser().parse()
    → ParsedStatement (with full metadata)
  ↓ parsedStatements.append(statement)
  ↓ autoSelectMatchingTarget()
```

**ParsedStatement model (full metadata):**
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
    public let metadata: StatementMetadata?
}
```

**Status**: Parser extracts all needed metadata successfully.

---

### 3. Preview Display

```
ImportView.previewView
  ↓ ImportPreviewView(viewModel: viewModel)
    → fileListSection()
    → aggregatedSummarySection()  
    → targetSelectionSection
    → aggregatedTransactionListSection()
```

Sections render `viewModel.parsedStatements` data correctly.

**Status**: Preview displays parsed data. No loss here.

---

### 4. Account Creation Trigger

```
ImportPreviewView.targetSelectionSection
  ↓ Menu("Create New Account...")
  ↓ Button(action: { initializeCreateSheet(isCard: false) })
    → initializeCreateSheet(isCard: Bool)
```

**The critical function `initializeCreateSheet`:**

```swift
func initializeCreateSheet(isCard: Bool) {
    guard let statement = viewModel.parsedStatements.first else {
        detectedBank = "Unknown"
        self.isCard = isCard
        newEntityName = ""
        newEntityOwnerName = ""
        newEntityLast4 = ""
        showCreateSheet = true
        return  // ← EARLY RETURN IF NO STATEMENT
    }

    let detected = statement.bankName.isEmpty ? "Unknown" : statement.bankName
    detectedBank = detected
    self.isCard = isCard

    if isCard {
        let cardLast4 = statement.cardLast4 ?? ""
        let nameConstructed = !cardLast4.isEmpty
            ? "\(detected) •••• \(cardLast4)"
            : detected
        newEntityName = nameConstructed
        newEntityNickname = ""
        newEntityLast4 = cardLast4      // ← SHOULD BE PREFILLED
        newEntityOwnerName = ""
    } else {
        let accountLast4 = statement.accountLast4 ?? ""
        let displayName = statement.accountName.isEmpty ? detected : statement.accountName
        let nameConstructed = !accountLast4.isEmpty
            ? "\(displayName) •••• \(accountLast4)"
            : displayName
        newEntityName = nameConstructed
        newEntityNickname = ""
        newEntityLast4 = accountLast4   // ← SHOULD BE PREFILLED
        newEntityOwnerName = statement.metadata?.customerName ?? ""
    }

    let matchingBank = viewModel.banks.first { bank in
        ImportFormatting.fuzzyMatch(bank.name, detected)
    }
    newEntityBankID = matchingBank?.id // ← FUZZY MATCH (may fail)
    showCreateSheet = true
}
```

**Status**: Logic looks correct, BUT...

---

### 5. Problems in Account Creation Sheet

#### Problem A: Bank Selection Logic

```swift
let matchingBank = viewModel.banks.first { bank in
    ImportFormatting.fuzzyMatch(bank.name, detected)
}
newEntityBankID = matchingBank?.id
```

**Issue**: 
- Only finds bank if fuzzy match succeeds
- If no match → `newEntityBankID = nil`
- User's original selectedSource (HDFC Bank) **is never used**
- If banks array hasn't loaded → fuzzy match fails

**Result**: Bank picker shows empty despite HDFC selection at import start.

---

#### Problem B: CreateNewTargetSheet Display

```swift
VStack(alignment: .leading, spacing: 8) {
    Text("Current Bank")
        .labelSmall()
    HStack {
        if let bank = selectedBank {
            Text(bank.name)
        } else {
            Text(detectedBank)  // ← Shows "Unknown" if fuzzy match failed
        }
    }
}

if !banks.isEmpty {
    Picker("Bank", selection: $bankID) {
        Text("Select Bank").tag(UUID?.none)
        ForEach(banks) { bank in
            Text(bank.name).tag(UUID?(bank.id))
        }
    }
}
```

**Issue**:
- Current Bank shows detectedBank (hardcoded text, not auto-selected in picker)
- Picker only shown if banks array not empty
- If fuzzy match failed, user must manually select bank
- Original selectedSource (HDFC Bank) is lost

---

#### Problem C: StatementMetadata Field Missing

```swift
// In ImportPreviewView line 45-46:
let metadata = viewModel.parsedStatements.first?.metadata
let accountType = metadata?.accountType ?? "savings"
```

**Issue**: StatementMetadata struct doesn't have `accountType` field.

**Actual StatementMetadata fields:**
```swift
struct StatementMetadata {
    let parsedTransactions: [ParsedTransaction]
    let periodStart: Date?
    let periodEnd: Date?
    let totalDebit: Int64
    let totalCredit: Int64
}
```

Result: `accountType` access returns nil, defaults to "savings" (correct fallback, but metadata design incomplete).

---

#### Problem D: Missing customerName in Metadata

```swift
// Line 112:
newEntityOwnerName = statement.metadata?.customerName ?? ""
```

**Issue**: StatementMetadata doesn't have `customerName` field.

Result: Owner name never prefilled from parsed statement.

---

### 6. Target Creation

```swift
// onCreate handler in CreateNewTargetSheet
Task {
    let metadata = viewModel.parsedStatements.first?.metadata
    let accountType = metadata?.accountType ?? "savings"
    await viewModel.createTargetFromDetected(
        customName: newEntityName,
        nickname: newEntityNickname,
        last4: newEntityLast4,          // ← From bindings (may be empty)
        bankID: newEntityBankID,        // ← May be nil (fuzzy match failed)
        ownerName: newEntityOwnerName,  // ← May be empty
        accountType: accountType,
        isCard: isCard
    )
    showCreateSheet = false
}
```

Then:

```swift
func createTargetFromDetected(...) async {
    guard let statement = parsedStatements.first else { ... }
    
    let bank = try await resolveOrCreateBank(
        for: statement,
        providedBankID: bankID  // ← May be nil
    )
    
    // Creates Ledger with provided values
    let ledger = Ledger(
        bankId: bank.id,
        kind: .bankAccount,
        displayName: customName ?? statement.bankName,
        last4: last4,               // ← May be empty if form wasn't prefilled
        ownerName: ownerName,       // ← May be empty
        ...
    )
}
```

**Status**: Account creation works, but uses empty/nil values if form wasn't prefilled.

---

## Root Causes

### 1. No Unified Import Session
```
Current: Scattered state in ImportViewModel + ImportPreviewView
@Observable ImportViewModel {
    selectedSource: StatementSource?
    parsedStatements: [ParsedStatement]
    selectedTarget: TransactionImportTarget?
    ledgers: [Ledger]
    banks: [Bank]
}

@State ImportPreviewView {
    newEntityName: String
    newEntityLast4: String
    newEntityBankID: UUID?
    detectedBank: String
    isCard: Bool
}

Problem: State lives in 2 places. Data duplication. No single source of truth.
```

### 2. Selected Bank Lost Between Layers
```
ImportView.selectedSource = StatementSource(HDFC Bank)
    ↓
ParsedStatement.bankName = "HDFC Bank"
    ↓
InitializeCreateSheet tries fuzzy matching...
    ↓
If fuzzy match fails:
    newEntityBankID = nil  ← LOST ORIGINAL SELECTION
```

### 3. Metadata Not Systematically Extracted
```
Parser extracts all metadata into ParsedStatement ✓
But StatementMetadata struct is incomplete:
- Missing customerName
- Missing accountType
- Missing ledgerKind (account vs card detection)
- Missing full account number

Downstream code tries to access missing fields.
```

### 4. Form Binding Reset
```
@State var newEntityLast4 = ""  ← Default empty

initializeCreateSheet() tries to set:
    newEntityLast4 = statement.accountLast4 ?? ""

But if this function is not called, or called with empty statement:
    User sees empty form
```

### 5. No Automatic Account Matching
```
Currently: Must manually select account from dropdown
Should: 
    - Extract last4 from statement
    - Match against existing ledgers
    - Auto-select if high confidence
    - Show "Matched: HDFC •••• 1234" instead of "Select Account"
```

---

## State Ownership Problems

| State | Current Location | Should Be | Problem |
|-------|------------------|-----------|---------|
| selectedSource | ImportViewModel | ImportSession | Lost after parsing |
| parsedStatements | ImportViewModel | ImportSession | Correct |
| newEntityLast4 | ImportPreviewView @State | ImportSession | Rebuilt on each view |
| newEntityBankID | ImportPreviewView @State | ImportSession | Depends on fuzzy match |
| selectedTarget | ImportViewModel | ImportSession | Correct |
| detectedBank | ImportPreviewView @State | ImportSession | Never synced with selectedSource |
| isCard | ImportPreviewView @State | ImportSession | Inferred from metadata, not persisted |

---

## Data Flow Gaps

### Gap 1: Bank Selection Context
```
User action: "Select HDFC Bank"
    ↓ Stored in: ImportViewModel.selectedSource ✓
    ↓ Passed to: parseFiles() ✓
    ↓ Used for: StatementDetector.detect() ✓
    ↓ But NOT passed to: CreateNewTargetSheet ✗

Result: Bank field empty when user creates account
```

### Gap 2: Account Metadata
```
Parser extracts: bankName, accountLast4, cardLast4, accountName ✓
Stored in: ParsedStatement ✓
Passed to: ImportPreviewView ✓
initializeCreateSheet() reads: statement.accountLast4 ✓
Sets: newEntityLast4 = statement.accountLast4 ✓
But if initializeCreateSheet() not called: Form empty ✗
```

### Gap 3: Metadata Completeness
```
ParsedStatement has:
    ✓ bankName
    ✓ accountLast4 / cardLast4
    ✗ accountType (missing from StatementMetadata)
    ✗ customerName (missing from StatementMetadata)
    ✗ full account number (only last4)
    ✗ statement type detection (savings vs credit vs loan)
```

---

## Data Duplication

| Data | Location 1 | Location 2 | Location 3 | Sync |
|------|-----------|-----------|-----------|------|
| bankName | ParsedStatement | initializeCreateSheet (extracted) | CreateNewTargetSheet (detectedBank) | Manual |
| last4 | ParsedStatement | newEntityLast4 @State | Form binding | Manual |
| accountType | Missing | Hardcoded "savings" | createTargetFromDetected | N/A |
| isCard | cardLast4 != nil (inferred) | isCard @State | CreateNewTargetSheet | Manual |

---

## Current Workarounds & Hacks

1. **Fuzzy matching bank names** (ImportFormatting.fuzzyMatch)
   - Fragile, may fail for misspellings
   - No fallback to selectedSource

2. **Hardcoded "savings" default** (line 46)
   - Works, but metadata design is incomplete

3. **Manual state rebuilding** in initializeCreateSheet
   - Logic duplicated from ParsedStatement into @State vars
   - Gets out of sync if statement not available

4. **"Unknown" fallback** for bank
   - Hidden problem instead of showing user's original selection

---

## Architectural Issues

### Issue 1: Parser-UI Mismatch
Parser provides complete metadata, but UI doesn't consume it systematically.

### Issue 2: Transient Selection
selectedSource is treated as UI state, not import context.

### Issue 3: State Fragmentation
ImportViewModel + ImportPreviewView both own import state. Unclear ownership.

### Issue 4: Incomplete Metadata Model
StatementMetadata struct missing fields needed by UI (customerName, accountType).

### Issue 5: No Session Object
No object to represent "in-progress import". State scattered across View/ViewModel.

### Issue 6: Manual Account Matching
No automatic ledger matching. User must select account despite having last4 data.

---

## Proposed Architecture Changes

### Phase 2 Output (to follow)

Will define:
1. **ParsedStatementMetadata** (extend StatementMetadata)
2. **ImportSession** (unified state container)
3. **AccountMatcher** service
4. **State flow diagram**
5. **Migration strategy**

---

## Next Steps

1. ✅ Analysis complete (this document)
2. ⏳ Design Phase 2: New architecture
3. ⏳ Implementation Phase 3: Code changes


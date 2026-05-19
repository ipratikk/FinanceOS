# FinanceOS Coding Standards

Enforced via SwiftLint. Run `swiftlint lint` before committing.

## Line Length

**Max 120 characters per line.**

For long logging or string expressions, extract intermediate values:

```swift
// ❌ Too long
logger.info("Successfully parsed \(fileName, privacy: .public) with \(txnCount, privacy: .public) transactions")

// ✅ Use variables
let txnCount = statement.transactions.count
logger.info("Parsed \(fileName, privacy: .public): \(txnCount, privacy: .public) txns")
```

## Function Body Length

**Max 50 lines (excluding comments/whitespace).**

Extract helper methods for logic that exceeds this:

```swift
// ❌ Single large function
func importTransactions() {
    // 60+ lines of file processing and DB save
}

// ✅ Extract helpers
func importTransactions() {
    let transactions = try await processImportFiles(target: target)
    try await transactionRepository.insertTransactions(transactions)
}

private func processImportFiles(target: TransactionImportTarget) async throws -> [Transaction] {
    // File processing logic here
}
```

## Struct/Type Body Length

**Max 250 lines (struct/class body only).**

Extract view components or helper structs when exceeding this:

```swift
// ❌ Single 300+ line View struct
struct MyView: View {
    var body: some View { ... }
    var section1: some View { ... }
    var section2: some View { ... }
    var section3: some View { ... }
    // 200+ more lines
}

// ✅ Extract into separate files/views
struct MyView: View {
    var body: some View {
        VStack {
            Section1View()
            Section2View()
            Section3View()
        }
    }
}
```

## File Length

**Max 400 lines per file.**

When approaching this limit, extract:
- View components into separate files
- Mock implementations (e.g., MockRepository)
- Helper structs/enums
- Complex view sections into dedicated View types

## For-Where Clauses

Prefer `where` clauses over nested `if` statements in `for` loops:

```swift
// ❌ Wrong
for item in items {
    if item.isValid {
        process(item)
    }
}

// ✅ Correct
for item in items where item.isValid {
    process(item)
}
```

## Multiple Closures

When a function takes multiple closures, do NOT use trailing closure syntax. Explicitly label all closure parameters:

```swift
// ❌ Wrong
Button(action: { showSheet = true }) {
    Label("Add", systemImage: "plus")
}

// ✅ Correct
Button(
    action: { showSheet = true },
    label: {
        Label("Add", systemImage: "plus")
    }
)
```

## Function Parameter Count

**Max 5 parameters.** For functions with 6+ parameters, group related parameters into a struct or use builder pattern:

```swift
// ❌ Wrong
func createCard(bank: Bank, statement: ParsedStatement, customName: String?, last4: String, cardType: CardType, nickname: String) async throws

// ✅ Correct - Extract parameters
struct CardCreationParams {
    let bank: Bank
    let statement: ParsedStatement
    let customName: String?
    let last4: String
    let cardType: CardType
    let nickname: String
}
func createCard(params: CardCreationParams) async throws
```

## Brace Spacing

Opening braces must have a space before them and be on the same line:

```swift
// ❌ Wrong
if condition
{
    // code
}

// ✅ Correct
if condition {
    // code
}
```

For multi-line conditions:

```swift
// ❌ Wrong
if let foo = bar,
   let baz = qux
{
    // code
}

// ✅ Correct
if let foo = bar,
   let baz = qux {
    // code
}
```

## String Conversion from Data

Use the failable initializer `String(bytes:encoding:)`:

```swift
// ❌ Wrong
let str = String(data: data, encoding: .utf8) ?? ""

// ✅ Correct - Use failable initializer when appropriate
if let str = String(bytes: data, encoding: .utf8) {
    // handle valid string
}

// Or with default if needed
let str = String(bytes: data, encoding: .utf8) ?? ""
```

## Optional Initialization

Use implicit initialization (no explicit `= nil`):

```swift
// ❌ Wrong
@State private var value: String? = nil

// ✅ Correct
@State private var value: String?
```

## Identifier Naming

Use camelCase. No underscores in variable names:

```swift
// ❌ Wrong
let target_desc = "value"
let file_name = "test.csv"

// ✅ Correct
let targetDesc = "value"
let fileName = "test.csv"
```

## Logging Best Practices

Keep log lines under 120 chars by extracting values first:

```swift
// ❌ Too long
logger.error("Unexpected error importing \(fileName, privacy: .public): \(error.localizedDescription, privacy: .public)")

// ✅ Extract variables
let desc = error.localizedDescription
logger.error("Import error for \(fileName, privacy: .public): \(desc, privacy: .public)")
```

Use abbreviations in logs to save space:
- `txns` instead of `transactions`
- `stmts` instead of `statements`
- `desc` instead of `localizedDescription`

Always use the FinanceLogger with a static string and attributes dictionary for logging.
Do not use print statements

## Enforcement

All files are checked via `swiftlint lint`. Fix violations before committing:

```bash
swiftlint lint                    # Check all files
swiftlint lint --path <file>     # Check specific file
swiftlint --fix --path <file>    # Auto-fix where possible
```

### SwiftFormat / SwiftLint Conflict

If `swiftformat` runs during build and reformats braces to new lines (conflicting with swiftlint's `opening_brace` rule):

1. **Prevent auto-formatting**: Disable swiftformat build phase or configure it to skip these patterns
2. **Manual format**: Format code with braces on same line before commit
3. **Pragmas**: Use `// swiftformat:disable all` / `// swiftformat:enable all` to prevent reformatting specific blocks

Ensure `.swiftformat` and `.swiftlint.yml` configurations are in sync.

## Folder Structure & SOLID Principles

### Presentation Layer Organization

```
Presentation/
├── Shared/
│   ├── Models/
│   │   ├── TransactionRow.swift
│   │   ├── TransactionSection.swift
│   │   ├── TransactionListState.swift
│   │   └── TransactionModels.swift (index)
│   └── Views/
│       ├── TransactionListContentView.swift
│       └── TransactionFilterView.swift
├── Transactions/
│   ├── TransactionsView.swift
│   └── TransactionsViewModel.swift
├── Accounts/
│   ├── AccountTransactionsView.swift
│   └── AccountTransactionsViewModel.swift
└── Cards/
    ├── CardTransactionsView.swift
    └── CardTransactionsViewModel.swift
```

### Guidelines

**Shared Models** (Shared/Models/):
- Types used across multiple features (TransactionRow, TransactionSection)
- Observable state containers shared by ViewModels (TransactionListState)
- Index file documents the purpose and usage

**Shared Views** (Shared/Views/):
- View components used by multiple features (TransactionListContentView, TransactionFilterView)
- Keep reusable, feature-agnostic

**Feature Folders** (Transactions/, Accounts/, Cards/):
- Feature-specific Views and ViewModels
- Import shared models/views as needed

**Extension Files** (when applicable):
- Use `+<Category>.swift` for large files approaching size limits
- Example: `TransactionListState+Filtering.swift` for complex filter logic
- Only when it improves clarity and reduces cognitive load per file

### SOLID Principles Applied

- **Single Responsibility**: Models, Views, ViewModels in separate files
- **Open/Closed**: Easy to extend without modifying existing feature folders
- **Liskov Substitution**: Clear, predictable contracts between layers
- **Interface Segregation**: Focused, single-purpose types
- **Dependency Inversion**: ViewModels depend on repositories (not directly on persistence)

## Architecture Alignment

These standards support the core architecture patterns:

- **Small functions** encourage single responsibility
- **Short files** force logical separation (View ↔ ViewModel ↔ Repository)
- **Line length limits** improve readability and reduce cognitive load
- **Clear naming** (no underscores) maintains consistency with Swift conventions
- **Folder structure** enforces separation of concerns and reusability

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

## Architecture Alignment

These standards support the core architecture patterns:

- **Small functions** encourage single responsibility
- **Short files** force logical separation (View ↔ ViewModel ↔ Repository)
- **Line length limits** improve readability and reduce cognitive load
- **Clear naming** (no underscores) maintains consistency with Swift conventions

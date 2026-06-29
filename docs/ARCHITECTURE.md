# FinanceOS Current Architecture

## Repo Structure

Apps/
Packages/

---

# FinanceCore Modules

* Database
* Models
* Repositories
* AppContainer
* Logging

---

# Database

* SQLite
* GRDB
* DatabaseQueue
* AppMigration
* DatabaseSeeder

---

# Current Data Access

* `ApolloGraphQLClient` — all app data (banks, ledgers, transactions)
* `TransactionRepository` / `GRDBTransactionRepository` — local only, used by `FinanceIntelligenceCLI`
* Intelligence repos (GRDB): persons, relationships, recurring patterns, graph, feedback

---

# Ledger Unification (Complete: Phases 8-10)

Unified Account/Card models into single Ledger model:
* Ledger struct with LedgerKind enum { bankAccount, creditCard, loan, wallet, crypto, investment }
* TransactionImportTarget: single .ledger(UUID) case
* ImportTargetMatcher: matches ledgers by accountLast4/cardLast4
* ParsedTransactionMapper: writes transaction.ledgerId with correct sign convention
* Migration v7_ledger_unification: backfills Account/Card into Ledger with 1:1 ID preservation
* UNIQUE INDEX (ledgerId, sourceFingerprint): deterministic deduplication
* Views: AccountsView, CardsView, AccountTransactionsView, CardTransactionsView all use Ledger
* All Account/Card models and repositories deleted
* ViewModels: ImportViewModel, AccountsViewModel, CardsViewModel use LedgerRepository

---

# Dependency Composition

* AppContainer exists
* DatabaseManager.shared owns DB lifecycle
* Repositories receive dbQueue via dependency injection

---

# Current UI Flow

SwiftUI View
→ ViewModel
→ ApolloGraphQLClient
→ financeos-backend GraphQL API

Intelligence pipeline (local):
→ TransactionIntelligenceService
→ GRDB SQLite (persons, relationships, recurring patterns, graph, feedback)

---

# Current Completed Features

* GraphQL thin client (Apollo iOS) — all CRUD via backend
* Bank, Ledger, Transaction data owned by financeos-backend
* Statement upload via `uploadStatement` GraphQL mutation
* Target matching by last4 digits (UI-side, pre-upload)
* Full UI layer: accounts, cards, transactions views via GraphQL
* AppContainer vends `graphQLClient` to all ViewModels
* Local intelligence pipeline: categorization, merchant, person, recurring pattern detection
* CategorizationScheduler: fetches from GraphQL, posts category back via `RecategorizeMutation`

---

# Current Naming

* dbQueue
* GRDB repositories
* LedgerKind: bankAccount, creditCard, loan, wallet, crypto, investment
* Ledger.displayName: unified account/card name
* Ledger.last4: unified last 4 digits
* Repository protocols in FinanceCore

---

# Completed Package Evolution

Packages/
├── FinanceCore ✅ (complete: models, DB, repositories, logging)
├── FinanceParsers ✅ (CSV/TXT parsing with bank-specific rules — HDFC, ICICI, Amex)
├── FinanceUI ✅ (design system, components, tokens)
└── FinanceTesting ✅ (mocks, fixtures, test utilities)

Future packages:
- FinanceSync (CloudKit sync)
- FinanceAnalytics (spending insights)
- FinanceAI (categorization, forecasting)

---

# Current Architectural Constraints

* UI must remain persistence-agnostic
* Repositories own GRDB interaction
* Parsing layer must remain isolated
* Avoid exposing database concerns outside repositories
* Keep import pipeline deterministic

---

# Ongoing Considerations

1. **Parser robustness**: Bank statement formats evolve; test against real-world samples
2. **Deduplication accuracy**: Monitor edge cases (same amount, same date, multiple sources)
3. **Scale performance**: N+1 query patterns in ViewModels; batch-load related data
4. **Merchant normalization**: Future work for categorization and analytics

---

# Presentation Layer Architecture (MVVM)

See `docs/MVVM_REFACTORING_PLAN.md` for the active refactoring plan enforcing these standards.

## Layer Diagram

```
SwiftUI View
  └─ binds to pre-formatted strings/bools from ViewModel
       └─ ViewModel (@Observable @MainActor)
            ├─ calls Repository Protocols (read/write)
            └─ calls Service Protocols (aggregation, export, migration)
                 └─ Repository / Service concrete implementations
                      └─ GRDB → SQLite
```

## ViewModel Requirements

Every screen with async data or mutable domain state has a ViewModel. No exceptions.

**Required declaration:**
```swift
@Observable
@MainActor
final class ExampleViewModel: AsyncLoadable, DeletableViewModel {
    // Dependencies: private, protocol types only — never concrete GRDB types
    private let exampleRepository: any ExampleRepository
    private let exampleService: any ExampleServiceProtocol

    // State: pre-formatted strings and Bools — never raw domain types exposed
    private(set) var rows: [ExampleRow] = []
    private(set) var isLoading = false
    private(set) var errorMessage: String?

    // Init: all deps injected — no AppContainer.shared inside ViewModel
    init(exampleRepository: any ExampleRepository, exampleService: any ExampleServiceProtocol) { ... }

    // Lifecycle: called from View .task
    func load() async { await withLoading { ... } onError: { self.errorMessage = $0.localizedDescription } }

    // Actions: accept raw String from text fields; parse internally
    func save(rawInput: String) async { ... }

    // Private mapping: domain → presentation model
    private func makeRows(from items: [ExampleDomainModel]) -> [ExampleRow] { ... }
}
```

**Type rule:** Published collections are always presentation model arrays (`[TransactionRow]`, `[BankRow]`) — never domain model arrays (`[Transaction]`, `[Ledger]`). Mapping happens in a private `makeRows()` method.

**Input rule:** When a View has a text field bound to a save action, the ViewModel accepts raw `String` and performs all parsing, validation, and unit conversion internally.

**Error rule:** `errorMessage: String?` is a pre-formatted user-facing string. Never expose `Error` or typed throws to the View layer.

## View Layer Rules

**Allowed:**
- `@ViewBuilder` functions composing FDS components using ViewModel-vended values
- `@State` for strictly ephemeral UI: popover visibility, hover state, animation offsets, focus
- Calling ViewModel action methods in response to gestures: `Button { Task { await viewModel.delete(id:) } }`
- `.task { await viewModel.load() }`, `.onChange`, `.onAppear { viewModel.onAppear() }`

**Forbidden — zero exceptions:**
- Any call to `FormatterCache`, `MoneyFormatting`, `CategoryTaxonomy`, `CategorySymbol`, `CardDatabase`
- Any arithmetic on domain values: `/100` unit conversions, running balance, net savings, percentages
- Any `Dictionary(grouping:)`, `.filter {}`, `.reduce`, `.sorted {}`, `.prefix(N)` over domain collections
- Any keyword-matching or string classification logic (`lower.contains("salary")`)
- Any `AppContainer.shared` access
- Any repository protocol method calls
- Any `async func` defined on the View struct (service calls, persistence, intelligence)
- Any `@State var` holding a domain model type (`Ledger`, `Transaction`, `Bank`) except transient confirmation selection

## View Extension Rules (+Sections, +Cards, +Steps, +Helpers)

- Must contain only `@ViewBuilder` functions and layout-only computed `var`
- Must not define `private func` returning non-View types
- Must not contain `async func` that call services or repositories
- Must not mutate ViewModel internal state directly
- **The `+Methods` extension pattern is banned.** Methods that are not `@ViewBuilder` belong in the ViewModel.
- Any extension file with `// MARK: - Business Logic` is a violation.

## Presentation Models

**Naming:**
- `{Noun}Row` — single item display model (e.g., `TransactionRow`, `BankRow`)
- `{Noun}Section` — grouped list section (e.g., `TransactionSection`)
- `{Noun}Summary` — aggregated display (e.g., `CategorySpendSummary`, `MerchantSummary`)

**String property naming:** `amountText`, `dateText`, `balanceText`, `signedAmountText`, `percentageText`

**Placement:**
- Used by 1 ViewModel → same file as ViewModel
- Used by 2+ ViewModels → `Presentation/Shared/Models/`
- Never nested inside a ViewModel class/struct definition

**Currently canonical shared models:** `TransactionRow`, `TransactionSection`, `TransactionListState`, `DateRangeFilter`

## Service Layer

Extract to a Service when:
- Any computation iterating a full transaction or ledger collection (`reduce`, `Dictionary(grouping:)`, running balance loops)
- Multi-step cross-repository operations (create + migrate + delete)
- Any operation called from more than one ViewModel
- CSV/export serialization
- Duplicate detection pipelines
- Intelligence learning invocation

**Protocol requirement:** Every Service has a protocol. ViewModels depend on the protocol, not the concrete type. Injected via `init`.

**Placement:** Domain aggregation services → `FinanceCore/Services/`. Presentation-layer orchestration → `Presentation/{Domain}/Services/`.

**Naming:** `{Domain}Service` (e.g., `AnalyticsAggregatorService`, `AccountBalanceService`). Protocol suffix: `Protocol` (e.g., `AnalyticsAggregatorProtocol`).

## Navigation

- `AppNavigator` is the single navigation authority
- `SheetRoute` and `DetailDestination` enums define all destinations
- ViewModels constructed at router level (`DetailRouter` / `SheetView`) with resolved deps — never inside View `init` or `body`
- Views dismiss via `@Environment(\.dismiss)` triggered by ViewModel-published success flag
- No `NavigationLink(destination:)` wiring in leaf Views
- No `AppContainer.shared` in any View; only the composition root reads it

## AppContainer Rules

- Only read at scene/window entry point or router level
- Constructs and vends all ViewModels and Services
- Views never access `AppContainer.shared` directly

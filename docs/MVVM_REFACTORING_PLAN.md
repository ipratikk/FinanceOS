# MVVM Refactoring Plan

Audit score: **6.1/10** across 8 domains. 74 violations found.
Each phase ships as an independent PR. Phases are sequential — do not start phase N+1 until phase N PR is merged.

See `docs/ARCHITECTURE.md` for enforced standards this plan enforces.

---

## Phase Status

| Phase | Title | Status | PR |
|-------|-------|--------|----|
| 1 | Missing ViewModels | ✅ done | #30 |
| 2 | Fix Transactions Split State | ✅ done | #31 |
| 3 | Dashboard Cleanup | ✅ done | #32 |
| 4 | Remove Repository Access from Views | ✅ done | #33 |
| 5 | Service Layer Extraction | 🔲 pending | — |
| 6 | Pre-format All Display Strings | 🔲 pending | — |
| 7 | Protocol Abstractions + Misc Cleanup | 🔲 pending | — |

---

## Phase 1 — Missing ViewModels

**Impact:** Critical. These are structural holes that all other violations flow through.
**Effort:** M per screen (7 screens total).

### Screens missing ViewModels

| Screen | File | Root violations |
|--------|------|-----------------|
| LedgerDetailView | `Presentation/Ledger/LedgerDetailView.swift` | `loadLedger()`, `formatBalance()`, utilization calc, `@State ledger/bank/isLoading` |
| SheetView | `Presentation/Navigation/SheetView.swift` | `@State banks/accounts`, repo fetches in `.task` |
| CardEditView | `Presentation/Cards/CardEditView.swift` | All `@State` form fields, `commitEdit`, `buildCreationState`, `seedBankFromCatalogIfNeeded`, `selectedCatalogCard` |
| CardSelectionView | `Presentation/Cards/CardSelectionView.swift` | `@State allCards/allIssuers/selectedIssuer`, `CardDatabase` calls, `filteredCards` |
| TransactionDetailView | `Presentation/Shared/Views/TransactionDetailView.swift` | `@State displayCategoryId/displayIsUserCorrected`, taxonomy lookups, `showNarration` flag |
| CategoryPickerView + CategoryPickerDestination | `Presentation/Intelligence/CategoryPickerView.swift`, `CategoryPickerDestination.swift` | `isSaving`, `save()`, `intelligence.learn()` — duplicated across both files |
| DestinationWrappers | `Presentation/Navigation/DestinationWrappers.swift` | `AccountTransactionsDestinationView` + `CardTransactionsDestinationView` fetch ledgers and do linear search inline |

### What to create

```
Presentation/Ledger/LedgerDetailViewModel.swift
Presentation/Navigation/SheetViewModel.swift
Presentation/Cards/CardEditViewModel.swift          ← dissolves CardEditContext.swift
Presentation/Cards/CardSelectionViewModel.swift
Presentation/Shared/Views/TransactionDetailViewModel.swift
Presentation/Intelligence/CategoryCorrectionViewModel.swift  ← shared by both picker screens
Presentation/Navigation/AccountTransactionsDestinationViewModel.swift
Presentation/Navigation/CardTransactionsDestinationViewModel.swift
```

### Rules
- Each ViewModel: `@Observable @MainActor final class`, conforms to `AsyncLoadable` where it loads async data
- `CardEditContext.swift` deleted — absorbed into `CardEditViewModel`
- `CategoryCorrectionViewModel` eliminates the `save()` + `isSaving` + `intelligence.learn()` duplication between the two picker files
- Views updated to inject ViewModel via `init(viewModel:)`; ViewModel constructed in router/coordinator

### Done when
- [ ] All 8 ViewModels exist and compile
- [ ] Their parent Views are updated to use them
- [ ] `CardEditContext.swift` deleted
- [ ] No `@State` holding domain model types (`Ledger`, `Transaction`, `Bank`) in any of the above Views
- [ ] No repository calls inside any of the above Views
- [ ] Lint passes, build succeeds

---

## Phase 2 — Fix Transactions Split State

**Impact:** High. `TransactionsView` duplicates its own ViewModel's filtering logic.
**Effort:** S.

### Problem
`TransactionsView` owns:
- `@State private var listState = TransactionListState()` — disconnected from `viewModel.listState`
- `var filteredRows` — full filter pipeline (search, type, category, date range) reimplemented in View
- `var daySections` — groupBy + sort on View
- `@State private var searchDebounceTask` — manual debounce in View

`TransactionsViewModel` already has `var listState` and `var sections` — unused by the View.

### What to change

**`TransactionsView.swift`**
- Remove `@State private var listState`
- Remove `var filteredRows` computed property
- Remove `var daySections` computed property
- Remove `@State private var searchDebounceTask` and debounce loop
- Use `@Bindable var viewModel` (already `@Observable`)
- Read `viewModel.sections` for the list
- Bind filter controls to `viewModel.listState`

**`TransactionListState.swift`**
- Add `func setSearchQuery(_ query: String)` that handles internal 150ms debounce via stored `Task`

**`TransactionsViewModel.swift`**
- Confirm `var listState` and `var sections` are the canonical filter state (no changes needed if already wired)

### Done when
- [ ] `filteredRows`, `daySections`, `searchDebounceTask` deleted from `TransactionsView`
- [ ] `TransactionsView` binds to `viewModel.listState` only
- [ ] `TransactionListState.setSearchQuery(_:)` exists with debounce
- [ ] Filter, search, category, date-range all work correctly end-to-end
- [ ] Lint passes, build succeeds

---

## Phase 3 — Dashboard Cleanup

**Impact:** High. Eliminates 3 critical violations + AppContainer leak.
**Effort:** S.

### Problem
- `DashboardViewModel.recentTransactions` is `[Transaction]` — View does all formatting/categorization
- `categoryName(for:)` — keyword classifier on View
- `categorySymbol(for:)` — SFSymbol mapping on View extension
- `activityRow(_:)` — domain→display mapping inline in View
- `AppContainer.shared` accessed in `DashboardView` body (ViewModel constructed inline)

### What to change

**`DashboardViewModel.swift`**
- Change `recentTransactions: [Transaction]` → `[TransactionRow]`
- Map via `makeRows()` (same pattern as `TransactionsViewModel`)
- Populate `iconName: String` on `TransactionRow` using intelligence service or keyword fallback — in ViewModel, not View
- Add `netWorthMoMDeltaText: String?` computed property (formatted `+X.X%` / `-X.X%`)
- Move `exportNetWorthCSV()` to `SpendingService` (or defer to Phase 5)

**`DashboardView+RecentActivityCard.swift`**
- Delete `categoryName(for:)`, `categorySymbol(for:)`, `activityRow(_:)` from View extension
- `activityRow` now binds only to `TransactionRow` properties: `.displayTitle`, `.subtitle`, `.amountText`, `.iconName`, `.isDebit`

**`DashboardView+Cards.swift`**
- Remove `heroDeltaBadge` `String(format:)` percentage formatting — bind to `viewModel.netWorthMoMDeltaText`
- Remove `heroAmount` `FormatterCache.formatCurrency` call — expose `viewModel.currentNetWorthText: String`
- Remove `metricsRow` net savings arithmetic — expose `viewModel.netSavingsText: String`

**`DashboardView.swift`**
- Remove inline `AppContainer.shared` ViewModel construction
- Use existing `init(viewModel:)` overload — ViewModel constructed in `ContentView`/`DetailRouter`

### Done when
- [ ] `DashboardViewModel.recentTransactions` is `[TransactionRow]`
- [ ] No `categoryName(for:)` / `categorySymbol(for:)` in any Dashboard file
- [ ] No `FormatterCache` / `MoneyFormatting` calls in Dashboard Views
- [ ] No `AppContainer.shared` in `DashboardView` body
- [ ] Recent activity card renders correctly
- [ ] Lint passes, build succeeds

---

## Phase 4 — Remove Repository Access from Views

**Impact:** High. Closes AppContainer-leaks and direct-repo patterns.
**Effort:** M.

### Problem areas

| File | Violation |
|------|-----------|
| `CardsView.swift` | Stores `transactionRepository` + `ledgerRepository` as View properties |
| `AccountsView.swift` | Same — duplicate pattern |
| `AdaptiveNavigation.swift` / `DetailRouter` | `bankRepository.deleteAll()` inline in View body |
| `AnalyticsView.swift` | `AppContainer.shared` ViewModel construction in `.task` |

### What to change

**`CardsView.swift` / `AccountsView.swift`**
- Remove `private let transactionRepository` and `private let ledgerRepository` stored properties
- Remove them from `init` parameters
- Child ViewModels (`CardTransactionsViewModel`, `AccountTransactionsViewModel`) constructed in router — passed as ViewModels, not as raw repos

**`AdaptiveNavigation.swift` / `DetailRouter`**
- Create `SettingsViewModel.swift` (or expand existing `SettingsView` to have one)
- `SettingsViewModel.clearAllData()` calls `bankRepository.deleteAll()`
- Remove `onClearAll` closure injected into `SettingsView` — `SettingsView` calls `viewModel.clearAllData()` directly

**`AnalyticsView.swift`**
- Remove `AppContainer.shared` from `.task`
- ViewModel constructed in `ContentView`/router and injected via `init(viewModel:)`

### Done when
- [ ] No `*Repository` stored properties on any View struct
- [ ] No `AppContainer.shared` in any View body or `.task`
- [ ] `SettingsViewModel` exists with `clearAllData()`
- [ ] All child ViewModels constructed at router level, not in View init
- [ ] Lint passes, build succeeds

---

## Phase 5 — Service Layer Extraction

**Impact:** High. Removes aggregation loops from ViewModels.
**Effort:** L.

### Problem
ViewModels contain financial computation that belongs in services:
- `AnalyticsViewModel`: `aggregateMerchants`, `aggregateCategorySpend` — full reduce loops
- `AccountsViewModel.loadBalances`: balance arithmetic (`txns.reduce(...)`)
- `AccountsViewModel.convertToCard`: multi-step cross-repo migration
- `AccountTransactionsViewModel.makeTransactionRows`: running balance computation loop
- `DashboardViewModel.exportNetWorthCSV`: CSV serialization

### New services

**`AnalyticsAggregatorService`** (in `Presentation/Analytics/Services/` or `FinanceCore/Services/`)
```
protocol AnalyticsAggregatorProtocol
  func aggregateMerchants([Transaction]) -> [MerchantSummary]
  func aggregateCategorySpend([Transaction]) -> [CategorySpendSummary]
  func computeFluctuations([Transaction]) -> [FluctuationRow]

struct AnalyticsAggregatorService: AnalyticsAggregatorProtocol
```

**`AccountBalanceService`** (in `FinanceCore/Services/`)
```
protocol AccountBalanceProtocol
  func computeBalance(account: Ledger, transactions: [Transaction]) -> Int64
  func computeRunningBalances(transactions: [Transaction], closingBalance: Int64?) -> [UUID: Int64]

struct AccountBalanceService: AccountBalanceProtocol
```

**`ExportService`** (in `FinanceCore/Services/` or `Presentation/Export/Services/`)
```
protocol ExportServiceProtocol
  func netWorthCSV(series: [NetWorthPoint]) -> String

struct ExportService: ExportServiceProtocol
```

**`LedgerMigrationService`** (in `FinanceCore/Services/`)
```
protocol LedgerMigrationProtocol
  func convertToCard(account: Ledger, ...) async throws
  func convertToAccount(card: Ledger, ...) async throws

struct LedgerMigrationService: LedgerMigrationProtocol
```

### Injection pattern
All services injected into ViewModels via `init`. `AppContainer` constructs and vends concrete implementations.

### Done when
- [ ] All 4 services exist with protocols
- [ ] `AnalyticsViewModel` delegates aggregation to `AnalyticsAggregatorProtocol`
- [ ] `AccountsViewModel` delegates balance calc and migration to services
- [ ] `AccountTransactionsViewModel` delegates running balance to `AccountBalanceService`
- [ ] `DashboardViewModel.exportNetWorthCSV()` delegates to `ExportService`
- [ ] `AppContainer` constructs and vends all new services
- [ ] Lint passes, build succeeds

---

## Phase 6 — Pre-format All Display Strings

**Impact:** High. Eliminates 15 `FormatterCache`/`MoneyFormatting` violations from Views.
**Effort:** L.

### Problem
15 Views and View extensions call `FormatterCache`, `MoneyFormatting`, or perform unit conversions (`Decimal / 100`) directly. Views must bind to pre-formatted strings from ViewModels or presentation models.

### Changes to presentation models

**`TransactionRow.swift`** — add:
```swift
let amountText: String          // "₹1,234.56"
let signedAmountText: String    // "+₹1,234.56" / "-₹1,234.56"
let dateText: String            // "15 Jan 2025"
let iconName: String            // SF Symbol name (resolved in ViewModel, not View)
```

**Move to `Shared/Models/`:**
- `CategorySpendSummary` + `MerchantSummary` — currently in `AnalyticsViewModel.swift`
  - Add `amountText: String`, `percentageText: String`
- `AccountLedgerBalance` — currently nested in `AccountsViewModel`
  - Add `balanceText: String`, `balanceAsOfText: String?`
- Create `FluctuationRow.swift` — for `RecentFluctuationsCard`

### Views to clean up (remove FormatterCache/MoneyFormatting)
- `DashboardView+Cards.swift` — `heroAmount`, `heroDeltaBadge` (covered in Phase 3)
- `OpeningBalanceSheet.swift` — `ledgerRow`, Edit button action
- `TransactionsView.swift` — `dayHeader` (date + dayNet amount)
- `AccountTransactionsView.swift` — `formattedBalance()`, `formattedDate()`, `accountHeader`
- `RecentFluctuationsCard.swift` — `formatDate()`, `formatAmount()`
- `SpendingTrendCard.swift` — `formattedTotal`, `periodLabel`
- `TransactionDetailView.swift` — `FormatterCache.fullDayDate`, `FormatterCache.dayAndTime`, category badge
- `TopMerchantsCard.swift` — `MoneyFormatting.formatRounded`
- `CategoryBreakdownChart.swift` — `MoneyFormatting.formatRounded`
- `LedgerDetailView.swift` — `formatBalance()`
- `ImportTransactionListView.swift` — `shortReference()` truncation

### Done when
- [ ] `TransactionRow` carries `amountText`, `signedAmountText`, `dateText`, `iconName`
- [ ] `CategorySpendSummary`, `MerchantSummary`, `AccountLedgerBalance` in `Shared/Models/` with formatted string properties
- [ ] Zero `FormatterCache` / `MoneyFormatting` calls in any View or View extension
- [ ] Zero `Decimal / 100` unit conversions in any View
- [ ] Lint passes, build succeeds

---

## Phase 7 — Protocol Abstractions + Misc Cleanup

**Impact:** Medium. Closes remaining testability gaps and deduplicates shared logic.
**Effort:** S–M.

### 7a. Protocol-abstract Import services

**`ImportFileParser.swift`**
- Define `protocol StatementParsingProtocol`
- Make `ImportFileParser` conform
- Inject via `ImportViewModel.init`

**`ImportDuplicateDetector.swift`**
- Define `protocol DuplicateDetectingProtocol`
- Make `ImportDuplicateDetector` conform
- Inject via `ImportViewModel.init`
- Replace `fetchTransactions().filter` with `fetchTransactionsForLedger(_:)` in duplicate detection

### 7b. Deduplicate ImportSource mapping

`importSource(for:bank:)` exists identically in both `CardsView` and `AccountsView`:
- Create `ImportSourceResolver.swift` in `Presentation/Import/Services/`
- Static `func source(for ledger: Ledger, bank: Bank?) -> StatementSource?`
- Expose on `CardsViewModel` + `AccountsViewModel` as `func statementSource(for ledger: Ledger) -> StatementSource?`
- Remove from both Views

### 7c. Remove +Methods View extension pattern

`CardEditView+Methods.swift` contains `commitEdit` labeled `// MARK: - Business Logic`:
- File deleted (logic moved to `CardEditViewModel` in Phase 1)
- Ensure no View file has a `+Methods` extension after Phase 1

### 7d. Fix BankEditContext dead code

`BankEditContext.swift` has `linkedLedgers`, `loadLedgers()`, `updateBank()` never wired up:
- Either wire them into a proper `BankEditViewModel` or delete the dead code
- `BankEditView.swift` currently owns all edit logic — assess whether it needs a ViewModel (apply same rules as Phase 1)

### Done when
- [ ] `ImportFileParser` conforms to `StatementParsingProtocol`
- [ ] `ImportDuplicateDetector` conforms to `DuplicateDetectingProtocol`
- [ ] Both injected via `ImportViewModel.init` (no more inline instantiation)
- [ ] `ImportSourceResolver` exists; `importSource(for:bank:)` removed from Views
- [ ] `CardEditView+Methods.swift` deleted
- [ ] `BankEditContext` dead code resolved
- [ ] Lint passes, build succeeds

---

## Session Protocol

When starting a new Claude session to work on a phase:

1. User says: **"continue Phase N of the MVVM refactoring"**
2. Claude reads `docs/MVVM_REFACTORING_PLAN.md` and `docs/ARCHITECTURE.md`
3. Claude implements the phase in a worktree branch
4. Claude creates PR via `/create-pr`
5. Claude updates Phase Status table in this file (status → ✅ done, PR → link)
6. Claude **stops and waits** — does not advance to next phase
7. User merges PR and starts next session for Phase N+1

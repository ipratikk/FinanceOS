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

# Current Repositories

* BankRepository / GRDBBankRepository
* LedgerRepository / GRDBLedgerRepository
* TransactionRepository / GRDBTransactionRepository

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
→ Repository
→ GRDB
→ SQLite

---

# Current Completed Features

* Database initialization & migrations (v7_ledger_unification)
* Bank repository with seeding
* Ledger model with 6 LedgerKind variants
* Transaction model with ledgerId foreign key
* Deterministic deduplication via sourceFingerprint UNIQUE INDEX
* Import pipeline: ParsedStatement → Transaction with proper sign convention
* Target matching by last4 digits (accountLast4/cardLast4)
* Full UI layer: accounts, cards, transactions views all using Ledger
* AppContainer dependency composition with LedgerRepository
* Comprehensive E2E import tests (5 tests, full pipeline coverage)
* Repository tests (7 tests, CRUD + filtering + constraints)
* Migration tests (4 tests, backfill correctness)

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
├── FinanceParsers ✅ (CSV/XLSX/TXT parsing with bank-specific rules)
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

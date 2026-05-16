# FinanceOS Architecture Rules

## Stack

* SwiftUI
* GRDB
* SQLite
* Swift Packages
* Observation framework

---

# Architecture

SwiftUI View
→ ViewModel
→ Repository Protocol
→ GRDB Repository
→ SQLite

---

# Core Rules

* Views never access GRDB directly
* ViewModels never contain SQL
* Repositories encapsulate persistence
* DatabaseManager owns database lifecycle
* AppContainer owns dependency composition
* Prefer protocol abstractions for repositories/services
* Keep UI layer free from database dependencies
* Parser layer must remain isolated from persistence/UI

---

# Naming Conventions

## Protocols

* BankRepository
* LedgerRepository
* TransactionRepository

## Concrete Implementations

* GRDBBankRepository
* GRDBLedgerRepository
* GRDBTransactionRepository

## Database Handle

* dbQueue

## Composition Root

* AppContainer

---

# Project Goals

Primary focus:

* deterministic ingestion
* reliable parsing
* deduplication correctness
* scalable architecture
* maintainable persistence layer

Avoid:

* premature ML
* premature sync
* overengineering
* speculative abstractions

---

# Parsing Strategy

## CSV

* CodableCSV

## XLSX

* CoreXLSX

## PDF

* PDFKit
* OCR fallback only when necessary

Architecture:

File
→ Parser
→ NormalizedTransaction
→ Import Pipeline
→ Repository

---

# Current Modules

* Database (SQLite + GRDB)
* Models (Bank, Ledger, Transaction, LedgerKind)
* Repositories (Bank, Ledger, Transaction)
* Importing (Parser, Mapper, Matcher, Pipeline, Deduplicator)
* AppContainer (dependency composition)
* Logging (structured logging with attributes)

---

# Ledger Unification Summary

Single Ledger model replaces Account/Card split:
* LedgerKind enum: bankAccount, creditCard, loan, wallet, crypto, investment
* Ledger.id matches original Account.id or Card.id (migration v7 backfill)
* TransactionImportTarget simplified to ledger(UUID)
* ImportTargetMatcher filters by LedgerKind
* Transaction.ledgerId provides normalized source of truth
* UNIQUE INDEX on (ledgerId, sourceFingerprint) for deduplication
* LedgerEditView unifies account & card editing UIs

---

# Near-Term Targets

1. Refactor remaining ViewModels (Accounts, Cards) to use LedgerRepository
2. Deprecate and remove Account/Card/Institution models
3. Complete import flow end-to-end verification (Phase 9)
4. Parser protocol formalization
5. CSV/XLSX/PDF ingestion completion
6. Deduplication testing at scale

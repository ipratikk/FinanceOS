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

# Completed Phases (1-10)

1. Phase 1: Import flow analysis & architecture doc
2. Phase 2: Fix sign-convention bug in ParsedTransactionMapper
3. Phase 3: Add UNIQUE INDEX for deterministic deduplication
4. Phase 4: Tighten ImportTargetMatcher to prevent mis-routing
5. Phase 5: Hoist supportedSources to registry
6. Phase 6: Collapse TargetChoice ↔ TransactionImportTarget binding loops
7. Phase 7: Remove dead code and orphaned models
8. Phase 8: Design & implement Ledger unification (8.1-8.13 subphases)
9. Phase 9: Comprehensive E2E import flow tests
10. Phase 10: Complete UI layer migration to Ledger model

---

# Near-Term Targets

1. CSV/XLSX parser hardening (ICICI, HDFC, Axis, etc.)
2. Statement format auto-detection
3. Bank-specific parsing rules
4. OCR for scanned statements (fallback only)
5. Duplicate transaction detection at scale
6. Analytics & spending insights
7. Budget management system

# FinanceOS Architecture Rules

## Stack

* SwiftUI
* Apollo GraphQL (thin client) — all app data
* GRDB / SQLite (TransferEvent persistence only)
* Swift Packages
* Observation framework

---

# Architecture

SwiftUI View
→ ViewModel
→ ApolloGraphQLClient
→ financeos-backend (GraphQL API)

Local intelligence pipeline:
→ TransactionIntelligenceService
→ GRDB (persons, relationships, patterns, graph, feedback)

---

# Core Rules

* Views never access repositories or GraphQL client directly
* ViewModels call GraphQL via `ApolloGraphQLClient`
* `AppContainer` owns `graphQLClient`; all ViewModels receive it via init injection
* `DatabaseManager` owns local SQLite lifecycle (TransferEvent data only)
* Parser layer remains isolated from persistence/UI
* Intelligence logic owned by Python backend; `FinanceIntelligence` Swift package removed

---

# Naming Conventions

## GraphQL Client

* ApolloGraphQLClient

## Local Repositories (TransferEvent only)

* TransactionRepository (protocol, used by parser CLI)
* GRDBTransactionRepository

## Composition Root

* AppContainer (vends `graphQLClient`)

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

## CSV (fully supported)

* SwiftCSV

## TXT (fully supported)

* Custom line parser (HDFC Bank)

## XLSX (partial — CoreXLSX, Darwin only)

## PDF (experimental — HDFCPDFParser + VisionPDFTextExtractor)

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

1. CSV/TXT parser hardening (additional Indian banks — Axis, SBI planned)
2. Bank-specific parsing rules
3. OCR for scanned statements (fallback only)
4. GraphQL-backed insights endpoint (replaces local intelligence)
5. Budget management system

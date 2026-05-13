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

* InstitutionRepository
* TransactionRepository
* AccountRepository

## Concrete Implementations

* GRDBInstitutionRepository
* GRDBTransactionRepository
* GRDBAccountRepository

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

* Institutions
* Database
* AppContainer
* Repositories
* Logging

---

# Near-Term Targets

1. Accounts domain
2. Transactions domain
3. Import scaffolding
4. Parser protocols
5. CSV/XLSX ingestion
6. Deduplication engine

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

* InstitutionRepository
* GRDBInstitutionRepository

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

* Database initialization
* Migrations
* Institution seeding
* Repository abstraction
* Institution list flow
* AppContainer dependency composition

---

# Current Naming

* dbQueue
* GRDB repositories
* Repository protocols separated from implementations

---

# Planned Package Evolution

Packages/
├── FinanceCore
├── FinanceImport
│   ├── CSV
│   ├── XLSX
│   ├── PDF
│   ├── Parsers
│   ├── Detection
│   └── Normalization

---

# Next Steps

1. Accounts domain
2. Transactions domain
3. Import scaffolding
4. Parser protocols
5. CSV ingestion
6. XLSX ingestion
7. Deduplication engine

---

# Current Architectural Constraints

* UI must remain persistence-agnostic
* Repositories own GRDB interaction
* Parsing layer must remain isolated
* Avoid exposing database concerns outside repositories
* Keep import pipeline deterministic

---

# Current Risks

1. Bank statement inconsistency
2. Future parser complexity
3. Deduplication correctness
4. Merchant normalization scale

# FinanceOS Current Architecture

## Repo Structure

Apps/
Packages/

## FinanceCore Modules

- Database
- Models
- Repositories
- AppContainer
- Logging

## Database

- SQLite
- GRDB
- DatabaseQueue
- AppMigration
- DatabaseSeeder

## Current Repositories

- InstitutionRepository
- GRDBInstitutionRepository

## Dependency Composition

- AppContainer exists
- DatabaseManager.shared owns DB lifecycle

## Current UI Flow

SwiftUI View
→ ViewModel
→ Repository
→ GRDB
→ SQLite

## Current Completed Features

- Database initialization
- Migrations
- Institution seeding
- Repository abstraction
- Institution list flow

## Current Naming

- dbQueue
- GRDB repositories
- Repository protocols separated from implementations

## Next Steps

1. Accounts domain
2. Transactions domain
3. Import scaffolding
4. Parser protocols
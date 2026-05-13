# FinanceOS Architecture Rules

## Stack
- SwiftUI
- GRDB
- SQLite
- Swift Packages
- Observation framework

## Architecture

SwiftUI View
→ ViewModel
→ Repository Protocol
→ GRDB Repository
→ SQLite

## Rules

- Views never access GRDB directly
- ViewModels never contain SQL
- Repositories encapsulate persistence
- DatabaseManager owns database lifecycle
- AppContainer owns dependency composition
- Prefer protocol abstractions for repositories/services
- Keep UI layer free from database dependencies

## Naming

Protocol:
- InstitutionRepository

Implementation:
- GRDBInstitutionRepository

## Project Goals

Primary focus:
- deterministic ingestion
- reliable parsing
- deduplication correctness
- scalable architecture

Avoid:
- premature ML
- premature sync
- overengineering

## Current Modules

- Institutions
- Database
- AppContainer
- Repositories

## Next Targets

- Accounts domain
- Transactions domain
- Import pipeline scaffolding
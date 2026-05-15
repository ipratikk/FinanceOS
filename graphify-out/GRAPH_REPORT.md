# Graph Report - FinanceOS  (2026-05-15)

## Corpus Check
- 79 files · ~17,776 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 608 nodes · 793 edges · 50 communities (29 shown, 21 thin omitted)
- Extraction: 96% EXTRACTED · 4% INFERRED · 0% AMBIGUOUS · INFERRED: 32 edges (avg confidence: 0.8)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `fae8c9f8`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- [[_COMMUNITY_Community 0|Community 0]]
- [[_COMMUNITY_Community 1|Community 1]]
- [[_COMMUNITY_Community 2|Community 2]]
- [[_COMMUNITY_Community 3|Community 3]]
- [[_COMMUNITY_Community 4|Community 4]]
- [[_COMMUNITY_Community 5|Community 5]]
- [[_COMMUNITY_Community 6|Community 6]]
- [[_COMMUNITY_Community 7|Community 7]]
- [[_COMMUNITY_Community 8|Community 8]]
- [[_COMMUNITY_Community 9|Community 9]]
- [[_COMMUNITY_Community 10|Community 10]]
- [[_COMMUNITY_Community 11|Community 11]]
- [[_COMMUNITY_Community 12|Community 12]]
- [[_COMMUNITY_Community 13|Community 13]]
- [[_COMMUNITY_Community 14|Community 14]]
- [[_COMMUNITY_Community 15|Community 15]]
- [[_COMMUNITY_Community 16|Community 16]]
- [[_COMMUNITY_Community 17|Community 17]]
- [[_COMMUNITY_Community 18|Community 18]]
- [[_COMMUNITY_Community 19|Community 19]]
- [[_COMMUNITY_Community 20|Community 20]]
- [[_COMMUNITY_Community 21|Community 21]]
- [[_COMMUNITY_Community 22|Community 22]]
- [[_COMMUNITY_Community 23|Community 23]]
- [[_COMMUNITY_Community 24|Community 24]]
- [[_COMMUNITY_Community 25|Community 25]]
- [[_COMMUNITY_Community 26|Community 26]]
- [[_COMMUNITY_Community 27|Community 27]]
- [[_COMMUNITY_Community 28|Community 28]]
- [[_COMMUNITY_Community 29|Community 29]]
- [[_COMMUNITY_Community 30|Community 30]]
- [[_COMMUNITY_Community 31|Community 31]]
- [[_COMMUNITY_Community 32|Community 32]]
- [[_COMMUNITY_Community 33|Community 33]]
- [[_COMMUNITY_Community 34|Community 34]]
- [[_COMMUNITY_Community 35|Community 35]]
- [[_COMMUNITY_Community 36|Community 36]]
- [[_COMMUNITY_Community 37|Community 37]]
- [[_COMMUNITY_Community 38|Community 38]]
- [[_COMMUNITY_Community 39|Community 39]]
- [[_COMMUNITY_Community 43|Community 43]]
- [[_COMMUNITY_Community 44|Community 44]]
- [[_COMMUNITY_Community 45|Community 45]]
- [[_COMMUNITY_Community 49|Community 49]]

## God Nodes (most connected - your core abstractions)
1. `TabularTransactionDecoder` - 21 edges
2. `ImportViewModel` - 20 edges
3. `ImportPreviewView` - 13 edges
4. `ImportView` - 12 edges
5. `FinanceOS Coding Standards` - 12 edges
6. `HDFCCardStatementParser` - 12 edges
7. `GRDBTransactionRepository` - 11 edges
8. `GRDBAccountRepository` - 10 edges
9. `GRDBCardRepository` - 10 edges
10. `CardType` - 10 edges

## Surprising Connections (you probably didn't know these)
- `InstitutionsView` --shares_data_with--> `Institution Model`  [EXTRACTED]
  Apps/FinanceOSMac/FinanceOSMac/Presentation/Institutions/InstitutionsView.swift → Packages/FinanceCore/Sources/FinanceCore/Models/Institution.swift
- `DatabaseSeeder seedInstitutions` --shares_data_with--> `institutions SQLite Table`  [INFERRED]
  Packages/FinanceCore/Sources/FinanceCore/Database/Seed/DatabaseSeeder.swift → Packages/FinanceCore/Sources/FinanceCore/Models/Institution.swift
- `FinanceCore Example Test` --references--> `FinanceCore Module Marker`  [EXTRACTED]
  Packages/FinanceCore/Tests/FinanceCoreTests/FinanceCoreTests.swift → Packages/FinanceCore/Sources/FinanceCore/FinanceCore.swift
- `DatabaseManager shared lifecycle` --calls--> `FinanceLogger`  [EXTRACTED]
  Packages/FinanceCore/Sources/FinanceCore/Database/DatabaseManager.swift → Packages/FinanceCore/Sources/FinanceCore/Logging/FinanceLogger.swift
- `DatabaseManager seedDatabase` --calls--> `DatabaseSeeder seedInstitutions`  [EXTRACTED]
  Packages/FinanceCore/Sources/FinanceCore/Database/DatabaseManager.swift → Packages/FinanceCore/Sources/FinanceCore/Database/Seed/DatabaseSeeder.swift

## Hyperedges (group relationships)
- **Institution List Flow** — institutions_view, institutions_viewmodel, institutionrepository_protocol, grdbinstitutionrepository, institution_model [EXTRACTED 1.00]
- **Database Lifecycle Flow** — databasemanager_shared, databasemanager_migrator, appmigration_registermigrations, databasemanager_seed_database, databaseseeder_seedinstitutions [EXTRACTED 1.00]
- **Architecture Rules To Code** — architecture_layered_flow, architecture_database_lifecycle_rule, architecture_dependency_composition_rule, architecture_repository_abstraction_rule, architecture_ui_database_boundary_rule, architecture_persistence_encapsulation_rule [EXTRACTED 1.00]

## Communities (50 total, 21 thin omitted)

### Community 0 - "Community 0"
Cohesion: 0.05
Nodes (18): DatabaseManager, DetectedStatementMetadata, StatementDetector, ImportResult, ParsedStatement, StatementParser, TransactionImporting, InstitutionStatementParser (+10 more)

### Community 1 - "Community 1"
Cohesion: 0.05
Nodes (13): AccountEditView, AccountsView, AccountTransactionsView, CardEditView, CardsView, CardTransactionsView, CreateNewTargetSheet, InstitutionEditView (+5 more)

### Community 2 - "Community 2"
Cohesion: 0.08
Nodes (10): AccountTransactionsViewModel, CardTransactionsViewModel, convertXLSToCSV(), extractRows(), parseCSVString(), parseStatement(), TransactionListState, TransactionRow (+2 more)

### Community 3 - "Community 3"
Cohesion: 0.07
Nodes (8): MockAccountRepository, MockCardRepository, MockInstitutionRepository, MockTransactionImporter, MockTransactionRepository, DefaultTransactionImporter, InstitutionRepository, TransactionImporting

### Community 4 - "Community 4"
Cohesion: 0.08
Nodes (5): AmexCardStatementParser, HDFCBankStatementParser, ICICIBankStatementParser, ICICICardStatementParser, InstitutionStatementParser

### Community 5 - "Community 5"
Cohesion: 0.12
Nodes (9): CSVStatementParser, ParsedWorkbook, SharedStringsParserDelegate, WorksheetParserDelegate, XLSXStatementParser, XLSXWorkbookReader, NSObject, StatementParser (+1 more)

### Community 6 - "Community 6"
Cohesion: 0.15
Nodes (4): Equatable, ParsedTransaction, StatementMetadata, TabularTransactionDecoder

### Community 7 - "Community 7"
Cohesion: 0.07
Nodes (26): Architecture Alignment, Brace Spacing, code:swift (// ❌ Too long), code:block10 (Presentation/), code:swift (// ❌ Single large function), code:swift (// ❌ Single 300+ line View struct), code:swift (// ❌ Wrong), code:swift (// ❌ Wrong) (+18 more)

### Community 8 - "Community 8"
Cohesion: 0.15
Nodes (10): Hashable, ImportView, TargetChoice, account, card, createAccount, createCard, TransactionImportTarget (+2 more)

### Community 9 - "Community 9"
Cohesion: 0.1
Nodes (20): ALWAYS Read First, Architecture Rules, Build & Test Workflow, Change Scope Rules, code:bash (git rev-parse HEAD), code:bash (graphify update .), code:bash (git status), Coding Standards (+12 more)

### Community 11 - "Community 11"
Cohesion: 0.14
Nodes (16): Architecture, Composition Root, Concrete Implementations, Core Rules, CSV, Current Modules, Database Handle, FinanceOS Architecture Rules (+8 more)

### Community 12 - "Community 12"
Cohesion: 0.15
Nodes (4): AmexStatementDetector, HDFCStatementDetector, ICICIStatementDetector, StatementDetector

### Community 13 - "Community 13"
Cohesion: 0.19
Nodes (7): FetchableRecord, Identifiable, Account, Bank, Card, TransactionSection, PersistableRecord

### Community 14 - "Community 14"
Cohesion: 0.23
Nodes (13): Current Architectural Constraints, Current Completed Features, Current Naming, Current Repositories, Current Risks, Current UI Flow, Database, Dependency Composition (+5 more)

### Community 18 - "Community 18"
Cohesion: 0.18
Nodes (9): Error, TransactionImportError, invalidAmount, invalidDate, malformedFile, missingRequiredColumn, platformUnavailable, unsupportedFormat (+1 more)

### Community 19 - "Community 19"
Cohesion: 0.22
Nodes (6): Codable, Columns, Transaction, TransactionType, credit, debit

### Community 20 - "Community 20"
Cohesion: 0.2
Nodes (3): Columns, Institution, DatabaseSeeder

### Community 21 - "Community 21"
Cohesion: 0.24
Nodes (10): DatabaseManager makeDatabaseURL, DatabaseManager migrator, DatabaseManager seedDatabase, DatabaseManager shared lifecycle, DatabaseSeeder seedInstitutions, FinanceLogger, Institution createTable, Institution Model (+2 more)

### Community 28 - "Community 28"
Cohesion: 0.25
Nodes (7): CardType, amex, mastercard, other, rupay, visa, Columns

### Community 29 - "Community 29"
Cohesion: 0.29
Nodes (4): AccountRepository, CardRepository, MockAccountRepository, MockCardRepository

### Community 31 - "Community 31"
Cohesion: 0.29
Nodes (6): CaseIterable, BankProviderType, bank, credit, neobank, Columns

### Community 35 - "Community 35"
Cohesion: 0.33
Nodes (5): AccountType, credit, current, savings, Columns

### Community 36 - "Community 36"
Cohesion: 0.33
Nodes (5): StatementFileFormat, csv, pdf, xls, xlsx

## Knowledge Gaps
- **86 isolated node(s):** `savings`, `current`, `credit`, `Columns`, `bank` (+81 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **21 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `ImportView` connect `Community 8` to `Community 1`, `Community 29`?**
  _High betweenness centrality (0.135) - this node is a cross-community bridge._
- **Why does `TargetChoice` connect `Community 8` to `Community 29`?**
  _High betweenness centrality (0.064) - this node is a cross-community bridge._
- **Why does `GRDBTransactionRepository` connect `Community 23` to `Community 0`, `Community 33`, `Community 22`?**
  _High betweenness centrality (0.062) - this node is a cross-community bridge._
- **Are the 12 inferred relationships involving `String` (e.g. with `.importTransactions()` and `.extractCardLast4()`) actually correct?**
  _`String` has 12 INFERRED edges - model-reasoned connections that need verification._
- **What connects `savings`, `current`, `credit` to the rest of the system?**
  _86 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Community 0` be split into smaller, more focused modules?**
  _Cohesion score 0.05 - nodes in this community are weakly interconnected._
- **Should `Community 1` be split into smaller, more focused modules?**
  _Cohesion score 0.05 - nodes in this community are weakly interconnected._
# Graph Report - FinanceOS  (2026-05-15)

## Corpus Check
- 78 files · ~17,653 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 668 nodes · 899 edges · 58 communities (32 shown, 26 thin omitted)
- Extraction: 96% EXTRACTED · 4% INFERRED · 0% AMBIGUOUS · INFERRED: 38 edges (avg confidence: 0.8)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `f76ac5c4`
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
- [[_COMMUNITY_Community 40|Community 40]]
- [[_COMMUNITY_Community 41|Community 41]]
- [[_COMMUNITY_Community 42|Community 42]]
- [[_COMMUNITY_Community 43|Community 43]]
- [[_COMMUNITY_Community 44|Community 44]]
- [[_COMMUNITY_Community 45|Community 45]]
- [[_COMMUNITY_Community 46|Community 46]]
- [[_COMMUNITY_Community 47|Community 47]]
- [[_COMMUNITY_Community 51|Community 51]]
- [[_COMMUNITY_Community 52|Community 52]]
- [[_COMMUNITY_Community 53|Community 53]]
- [[_COMMUNITY_Community 57|Community 57]]

## God Nodes (most connected - your core abstractions)
1. `TabularTransactionDecoder` - 21 edges
2. `ImportViewModel` - 19 edges
3. `FinanceOS Coding Standards` - 16 edges
4. `ImportPreviewView` - 14 edges
5. `ImportView` - 13 edges
6. `HDFCCardStatementParser` - 12 edges
7. `ICICIBankStatementParser` - 11 edges
8. `GRDBTransactionRepository` - 11 edges
9. `AmexCardStatementParser` - 10 edges
10. `ParsedStatement` - 10 edges

## Surprising Connections (you probably didn't know these)
- `DatabaseSeeder seedInstitutions` --shares_data_with--> `institutions SQLite Table`  [INFERRED]
  Packages/FinanceCore/Sources/FinanceCore/Database/Seed/DatabaseSeeder.swift → Packages/FinanceCore/Sources/FinanceCore/Models/Institution.swift
- `FinanceCore Example Test` --references--> `FinanceCore Module Marker`  [EXTRACTED]
  Packages/FinanceCore/Tests/FinanceCoreTests/FinanceCoreTests.swift → Packages/FinanceCore/Sources/FinanceCore/FinanceCore.swift
- `DatabaseManager shared lifecycle` --calls--> `FinanceLogger`  [EXTRACTED]
  Packages/FinanceCore/Sources/FinanceCore/Database/DatabaseManager.swift → Packages/FinanceCore/Sources/FinanceCore/Logging/FinanceLogger.swift
- `DatabaseManager seedDatabase` --calls--> `DatabaseSeeder seedInstitutions`  [EXTRACTED]
  Packages/FinanceCore/Sources/FinanceCore/Database/DatabaseManager.swift → Packages/FinanceCore/Sources/FinanceCore/Database/Seed/DatabaseSeeder.swift
- `DatabaseSeeder seedInstitutions` --calls--> `Institution Model`  [EXTRACTED]
  Packages/FinanceCore/Sources/FinanceCore/Database/Seed/DatabaseSeeder.swift → Packages/FinanceCore/Sources/FinanceCore/Models/Institution.swift

## Hyperedges (group relationships)
- **Institution List Flow** — institutions_view, institutions_viewmodel, institutionrepository_protocol, grdbinstitutionrepository, institution_model [EXTRACTED 1.00]
- **Database Lifecycle Flow** — databasemanager_shared, databasemanager_migrator, appmigration_registermigrations, databasemanager_seed_database, databaseseeder_seedinstitutions [EXTRACTED 1.00]
- **Architecture Rules To Code** — architecture_layered_flow, architecture_database_lifecycle_rule, architecture_dependency_composition_rule, architecture_repository_abstraction_rule, architecture_ui_database_boundary_rule, architecture_persistence_encapsulation_rule [EXTRACTED 1.00]

## Communities (58 total, 26 thin omitted)

### Community 0 - "Community 0"
Cohesion: 0.05
Nodes (7): ParsedStatement, AmexCardStatementParser, HDFCBankStatementParser, HDFCCardStatementParser, ICICIBankStatementParser, ICICICardStatementParser, InstitutionStatementParser

### Community 1 - "Community 1"
Cohesion: 0.05
Nodes (19): DatabaseManager, ImportResult, StatementParser, TransactionImporting, InstitutionStatementParser, StatementParserRegistry, AccountRepository, BankRepository (+11 more)

### Community 2 - "Community 2"
Cohesion: 0.07
Nodes (34): Architecture Alignment, Brace Spacing, code:swift (// ❌ Too long), code:swift (// ❌ Wrong), code:swift (// ❌ Wrong), code:swift (// ❌ Too long), code:bash (swiftlint lint                    # Check all files), code:block14 (Presentation/) (+26 more)

### Community 3 - "Community 3"
Cohesion: 0.07
Nodes (8): MockAccountRepository, MockCardRepository, MockInstitutionRepository, MockTransactionImporter, MockTransactionRepository, DefaultTransactionImporter, InstitutionRepository, TransactionImporting

### Community 4 - "Community 4"
Cohesion: 0.06
Nodes (7): AppContainer, CardRepository, MockCardRepository, TransactionImportPipeline, GRDBAccountRepository, GRDBCardRepository, GRDBInstitutionRepository

### Community 5 - "Community 5"
Cohesion: 0.13
Nodes (12): fileFormat(), formatError(), fuzzyMatch(), ImportViewModel, isSameTransaction(), logDebug(), logInfo(), transactionHash() (+4 more)

### Community 6 - "Community 6"
Cohesion: 0.12
Nodes (9): CSVStatementParser, ParsedWorkbook, SharedStringsParserDelegate, WorksheetParserDelegate, XLSXStatementParser, XLSXWorkbookReader, NSObject, StatementParser (+1 more)

### Community 7 - "Community 7"
Cohesion: 0.15
Nodes (4): Equatable, ParsedTransaction, StatementMetadata, TabularTransactionDecoder

### Community 8 - "Community 8"
Cohesion: 0.12
Nodes (12): AccountRepository, Hashable, ImportView, MockAccountRepository, TargetChoice, account, card, createAccount (+4 more)

### Community 9 - "Community 9"
Cohesion: 0.11
Nodes (4): AccountTransactionsViewModel, CardTransactionsViewModel, TransactionRow, TransactionsViewModel

### Community 10 - "Community 10"
Cohesion: 0.1
Nodes (20): ALWAYS Read First, Architecture Rules, Build & Test Workflow, Change Scope Rules, code:bash (git rev-parse HEAD), code:bash (graphify update .), code:bash (git status), Coding Standards (+12 more)

### Community 11 - "Community 11"
Cohesion: 0.12
Nodes (6): AmexStatementDetector, HDFCStatementDetector, ICICIStatementDetector, DetectedStatementMetadata, StatementDetector, StatementDetector

### Community 12 - "Community 12"
Cohesion: 0.14
Nodes (16): Architecture, Composition Root, Concrete Implementations, Core Rules, CSV, Current Modules, Database Handle, FinanceOS Architecture Rules (+8 more)

### Community 13 - "Community 13"
Cohesion: 0.13
Nodes (3): MockTransactionRepository, GRDBTransactionRepository, TransactionRepository

### Community 15 - "Community 15"
Cohesion: 0.19
Nodes (7): FetchableRecord, Identifiable, Account, Bank, Card, TransactionSection, PersistableRecord

### Community 16 - "Community 16"
Cohesion: 0.23
Nodes (13): Current Architectural Constraints, Current Completed Features, Current Naming, Current Repositories, Current Risks, Current UI Flow, Database, Dependency Composition (+5 more)

### Community 17 - "Community 17"
Cohesion: 0.15
Nodes (3): BankRepository, MockBankRepository, GRDBBankRepository

### Community 18 - "Community 18"
Cohesion: 0.17
Nodes (10): CaseIterable, StatementFileFormat, csv, pdf, xlsx, AccountType, credit, current (+2 more)

### Community 20 - "Community 20"
Cohesion: 0.18
Nodes (9): Error, TransactionImportError, invalidAmount, invalidDate, malformedFile, missingRequiredColumn, platformUnavailable, unsupportedFormat (+1 more)

### Community 21 - "Community 21"
Cohesion: 0.2
Nodes (3): Columns, Institution, DatabaseSeeder

### Community 22 - "Community 22"
Cohesion: 0.22
Nodes (6): Codable, Columns, Transaction, TransactionType, credit, debit

### Community 23 - "Community 23"
Cohesion: 0.28
Nodes (9): DatabaseManager makeDatabaseURL, DatabaseManager migrator, DatabaseManager seedDatabase, DatabaseManager shared lifecycle, DatabaseSeeder seedInstitutions, FinanceLogger, Institution createTable, Institution Model (+1 more)

### Community 24 - "Community 24"
Cohesion: 0.57
Nodes (6): convertXLSToCSV(), extractRows(), findSSConvert(), init(), parseCSVString(), parseStatement()

### Community 26 - "Community 26"
Cohesion: 0.25
Nodes (7): CardType, amex, mastercard, other, rupay, visa, Columns

### Community 30 - "Community 30"
Cohesion: 0.33
Nodes (5): BankProviderType, bank, credit, neobank, Columns

### Community 33 - "Community 33"
Cohesion: 0.4
Nodes (3): View, TransactionFilterView, TransactionListContentView

## Knowledge Gaps
- **87 isolated node(s):** `code:swift (// ❌ Too long)`, `code:swift (// ❌ Single large function)`, `code:swift (// ❌ Single 300+ line View struct)`, `File Length`, `code:swift (// ❌ Wrong)` (+82 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **26 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `ImportView` connect `Community 8` to `Community 33`?**
  _High betweenness centrality (0.144) - this node is a cross-community bridge._
- **Why does `ParsedStatement` connect `Community 0` to `Community 1`, `Community 7`?**
  _High betweenness centrality (0.089) - this node is a cross-community bridge._
- **Why does `TransactionImportTarget` connect `Community 8` to `Community 1`, `Community 7`?**
  _High betweenness centrality (0.078) - this node is a cross-community bridge._
- **Are the 15 inferred relationships involving `String` (e.g. with `logInfo()` and `logDebug()`) actually correct?**
  _`String` has 15 INFERRED edges - model-reasoned connections that need verification._
- **What connects `code:swift (// ❌ Too long)`, `code:swift (// ❌ Single large function)`, `code:swift (// ❌ Single 300+ line View struct)` to the rest of the system?**
  _87 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Community 0` be split into smaller, more focused modules?**
  _Cohesion score 0.05 - nodes in this community are weakly interconnected._
- **Should `Community 1` be split into smaller, more focused modules?**
  _Cohesion score 0.05 - nodes in this community are weakly interconnected._
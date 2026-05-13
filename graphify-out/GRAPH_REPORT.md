# Graph Report - FinanceOS  (2026-05-13)

## Corpus Check
- 53 files · ~10,254 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 343 nodes · 447 edges · 32 communities (18 shown, 14 thin omitted)
- Extraction: 97% EXTRACTED · 3% INFERRED · 0% AMBIGUOUS · INFERRED: 15 edges (avg confidence: 0.8)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `959f13fa`
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
- [[_COMMUNITY_Community 24|Community 24]]
- [[_COMMUNITY_Community 26|Community 26]]
- [[_COMMUNITY_Community 27|Community 27]]
- [[_COMMUNITY_Community 28|Community 28]]
- [[_COMMUNITY_Community 31|Community 31]]

## God Nodes (most connected - your core abstractions)
1. `TabularTransactionDecoder` - 19 edges
2. `ImportViewModel` - 12 edges
3. `ImportView` - 11 edges
4. `FinanceOS Current Architecture` - 10 edges
5. `Transaction` - 10 edges
6. `GRDBTransactionRepository` - 9 edges
7. `Institution` - 9 edges
8. `TransactionImportError` - 8 edges
9. `WorksheetParserDelegate` - 8 edges
10. `Card` - 8 edges

## Surprising Connections (you probably didn't know these)
- `InstitutionsViewModel` --references--> `InstitutionRepository Protocol`  [EXTRACTED]
  Apps/FinanceOSMac/FinanceOSMac/Presentation/Institutions/InstitutionsViewModel.swift → Packages/FinanceCore/Sources/FinanceCore/Repositories/InstitutionRepository.swift
- `InstitutionsViewModel loadInstitutions` --calls--> `InstitutionRepository Protocol`  [EXTRACTED]
  Apps/FinanceOSMac/FinanceOSMac/Presentation/Institutions/InstitutionsViewModel.swift → Packages/FinanceCore/Sources/FinanceCore/Repositories/InstitutionRepository.swift
- `InstitutionsView` --shares_data_with--> `Institution Model`  [EXTRACTED]
  Apps/FinanceOSMac/FinanceOSMac/Presentation/Institutions/InstitutionsView.swift → Packages/FinanceCore/Sources/FinanceCore/Models/Institution.swift
- `InstitutionsViewModel` --shares_data_with--> `Institution Model`  [EXTRACTED]
  Apps/FinanceOSMac/FinanceOSMac/Presentation/Institutions/InstitutionsViewModel.swift → Packages/FinanceCore/Sources/FinanceCore/Models/Institution.swift
- `FinanceOSMacApp` --references--> `AppContainer Shared Composition Root`  [EXTRACTED]
  Apps/FinanceOSMac/FinanceOSMac/FinanceOSMacApp.swift → Packages/FinanceCore/Sources/FinanceCore/AppContainer/AppContainer.swift

## Hyperedges (group relationships)
- **Institution List Flow** — institutions_view, institutions_viewmodel, institutionrepository_protocol, grdbinstitutionrepository, institution_model [EXTRACTED 1.00]
- **Database Lifecycle Flow** — databasemanager_shared, databasemanager_migrator, appmigration_registermigrations, databasemanager_seed_database, databaseseeder_seedinstitutions [EXTRACTED 1.00]
- **Architecture Rules To Code** — architecture_layered_flow, architecture_database_lifecycle_rule, architecture_dependency_composition_rule, architecture_repository_abstraction_rule, architecture_ui_database_boundary_rule, architecture_persistence_encapsulation_rule [EXTRACTED 1.00]

## Communities (32 total, 14 thin omitted)

### Community 0 - "Community 0"
Cohesion: 0.08
Nodes (17): Codable, FetchableRecord, Identifiable, Account, Columns, Card, Columns, Columns (+9 more)

### Community 1 - "Community 1"
Cohesion: 0.07
Nodes (16): AccountRepository, AppContainer, CardRepository, Hashable, MockAccountRepository, MockCardRepository, TargetChoice, account (+8 more)

### Community 2 - "Community 2"
Cohesion: 0.08
Nodes (11): DatabaseManager, DefaultTransactionImporter, ParsedStatement, StatementParser, TransactionImporting, AccountRepository, CardRepository, InstitutionRepository (+3 more)

### Community 3 - "Community 3"
Cohesion: 0.16
Nodes (4): Equatable, ParsedTransaction, StatementMetadata, TabularTransactionDecoder

### Community 4 - "Community 4"
Cohesion: 0.12
Nodes (9): CSVStatementParser, ParsedWorkbook, SharedStringsParserDelegate, WorksheetParserDelegate, XLSXStatementParser, XLSXWorkbookReader, NSObject, StatementParser (+1 more)

### Community 5 - "Community 5"
Cohesion: 0.11
Nodes (19): ALWAYS Read First, Architecture Rules, Build & Test Workflow, Change Scope Rules, code:bash (git rev-parse HEAD), code:bash (graphify update .), code:bash (git status), Context Loading Rules (+11 more)

### Community 6 - "Community 6"
Cohesion: 0.11
Nodes (7): AccountsView, AccountTransactionsView, CardsView, CardTransactionsView, InstitutionsView, TransactionsView, View

### Community 7 - "Community 7"
Cohesion: 0.18
Nodes (18): AppContainer Shared Composition Root, AppMigration registerMigrations, DatabaseManager makeDatabaseURL, DatabaseManager migrator, DatabaseManager seedDatabase, DatabaseManager shared lifecycle, DatabaseSeeder seedInstitutions, FinanceLogger (+10 more)

### Community 8 - "Community 8"
Cohesion: 0.14
Nodes (16): Architecture, Composition Root, Concrete Implementations, Core Rules, CSV, Current Modules, Database Handle, FinanceOS Architecture Rules (+8 more)

### Community 9 - "Community 9"
Cohesion: 0.23
Nodes (13): Current Architectural Constraints, Current Completed Features, Current Naming, Current Repositories, Current Risks, Current UI Flow, Database, Dependency Composition (+5 more)

### Community 10 - "Community 10"
Cohesion: 0.15
Nodes (3): MockTransactionRepository, GRDBTransactionRepository, TransactionRepository

### Community 12 - "Community 12"
Cohesion: 0.2
Nodes (7): CaseIterable, StatementFileFormat, csv, pdf, xlsx, String, TransactionsViewModel

### Community 14 - "Community 14"
Cohesion: 0.22
Nodes (8): Error, TransactionImportError, invalidAmount, invalidDate, malformedFile, missingRequiredColumn, platformUnavailable, unsupportedFormat

## Knowledge Gaps
- **53 isolated node(s):** `account`, `card`, `Stack`, `Core Rules`, `Protocols` (+48 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **14 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `ImportView` connect `Community 13` to `Community 1`, `Community 6`?**
  _High betweenness centrality (0.093) - this node is a cross-community bridge._
- **Why does `GRDBTransactionRepository` connect `Community 10` to `Community 1`, `Community 2`?**
  _High betweenness centrality (0.059) - this node is a cross-community bridge._
- **Why does `XLSXStatementParser` connect `Community 4` to `Community 2`?**
  _High betweenness centrality (0.054) - this node is a cross-community bridge._
- **What connects `account`, `card`, `Stack` to the rest of the system?**
  _53 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Community 0` be split into smaller, more focused modules?**
  _Cohesion score 0.08 - nodes in this community are weakly interconnected._
- **Should `Community 1` be split into smaller, more focused modules?**
  _Cohesion score 0.07 - nodes in this community are weakly interconnected._
- **Should `Community 2` be split into smaller, more focused modules?**
  _Cohesion score 0.08 - nodes in this community are weakly interconnected._
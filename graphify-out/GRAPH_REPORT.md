# Graph Report - FinanceOS  (2026-05-15)

## Corpus Check
- 110 files · ~29,351 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 957 nodes · 1323 edges · 74 communities (41 shown, 33 thin omitted)
- Extraction: 94% EXTRACTED · 6% INFERRED · 0% AMBIGUOUS · INFERRED: 80 edges (avg confidence: 0.8)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `8bf50196`
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
- [[_COMMUNITY_Community 48|Community 48]]
- [[_COMMUNITY_Community 49|Community 49]]
- [[_COMMUNITY_Community 50|Community 50]]
- [[_COMMUNITY_Community 51|Community 51]]
- [[_COMMUNITY_Community 52|Community 52]]
- [[_COMMUNITY_Community 53|Community 53]]
- [[_COMMUNITY_Community 54|Community 54]]
- [[_COMMUNITY_Community 55|Community 55]]
- [[_COMMUNITY_Community 56|Community 56]]
- [[_COMMUNITY_Community 57|Community 57]]
- [[_COMMUNITY_Community 58|Community 58]]
- [[_COMMUNITY_Community 59|Community 59]]
- [[_COMMUNITY_Community 60|Community 60]]
- [[_COMMUNITY_Community 61|Community 61]]
- [[_COMMUNITY_Community 62|Community 62]]
- [[_COMMUNITY_Community 63|Community 63]]
- [[_COMMUNITY_Community 67|Community 67]]
- [[_COMMUNITY_Community 68|Community 68]]
- [[_COMMUNITY_Community 73|Community 73]]

## God Nodes (most connected - your core abstractions)
1. `TabularTransactionDecoder` - 22 edges
2. `ImportViewModel` - 21 edges
3. `HDFCMetadataExtractor` - 18 edges
4. `HDFCPDFParser` - 16 edges
5. `FinanceOS Coding Standards` - 16 edges
6. `PDFStatementParser` - 14 edges
7. `ImportView` - 12 edges
8. `HDFCCardStatementParser` - 12 edges
9. `TransactionImportError` - 11 edges
10. `CodingKeys` - 11 edges

## Surprising Connections (you probably didn't know these)
- `DatabaseSeeder seedInstitutions` --shares_data_with--> `institutions SQLite Table`  [INFERRED]
  Packages/FinanceCore/Sources/FinanceCore/Database/Seed/DatabaseSeeder.swift → Packages/FinanceCore/Sources/FinanceCore/Models/Institution.swift
- `FinanceCore Example Test` --references--> `FinanceCore Module Marker`  [EXTRACTED]
  Packages/FinanceCore/Tests/FinanceCoreTests/FinanceCoreTests.swift → Packages/FinanceCore/Sources/FinanceCore/FinanceCore.swift
- `DatabaseManager seedDatabase` --calls--> `DatabaseSeeder seedInstitutions`  [EXTRACTED]
  Packages/FinanceCore/Sources/FinanceCore/Database/DatabaseManager.swift → Packages/FinanceCore/Sources/FinanceCore/Database/Seed/DatabaseSeeder.swift
- `DatabaseSeeder seedInstitutions` --calls--> `Institution Model`  [EXTRACTED]
  Packages/FinanceCore/Sources/FinanceCore/Database/Seed/DatabaseSeeder.swift → Packages/FinanceCore/Sources/FinanceCore/Models/Institution.swift

## Hyperedges (group relationships)
- **Institution List Flow** — institutions_view, institutions_viewmodel, institutionrepository_protocol, grdbinstitutionrepository, institution_model [EXTRACTED 1.00]
- **Database Lifecycle Flow** — databasemanager_shared, databasemanager_migrator, appmigration_registermigrations, databasemanager_seed_database, databaseseeder_seedinstitutions [EXTRACTED 1.00]
- **Architecture Rules To Code** — architecture_layered_flow, architecture_database_lifecycle_rule, architecture_dependency_composition_rule, architecture_repository_abstraction_rule, architecture_ui_database_boundary_rule, architecture_persistence_encapsulation_rule [EXTRACTED 1.00]

## Communities (74 total, 33 thin omitted)

### Community 0 - "Community 0"
Cohesion: 0.05
Nodes (7): ParsedStatement, AmexCardStatementParser, HDFCBankStatementParser, HDFCCardStatementParser, ICICIBankStatementParser, ICICICardStatementParser, InstitutionStatementParser

### Community 1 - "Community 1"
Cohesion: 0.04
Nodes (10): AccountRepository, AppContainer, BankRepository, MockAccountRepository, MockBankRepository, TransactionImportPipeline, GRDBAccountRepository, GRDBBankRepository (+2 more)

### Community 2 - "Community 2"
Cohesion: 0.07
Nodes (13): AccountTransactionsViewModel, CardTransactionsViewModel, HDFCLineClassifier, convertXLSToCSV(), extractRows(), findSSConvert(), init(), parseCSVString() (+5 more)

### Community 3 - "Community 3"
Cohesion: 0.05
Nodes (37): CodingKey, CustomStringConvertible, Error, CodingKeys, amountMinorUnits, currencyCode, description, id (+29 more)

### Community 4 - "Community 4"
Cohesion: 0.13
Nodes (9): fileFormat(), formatError(), fuzzyMatch(), ImportViewModel, isSameTransaction(), logDebug(), logInfo(), transactionHash() (+1 more)

### Community 5 - "Community 5"
Cohesion: 0.07
Nodes (34): Architecture Alignment, Brace Spacing, code:swift (// ❌ Too long), code:swift (// ❌ Wrong), code:swift (// ❌ Wrong), code:swift (// ❌ Too long), code:bash (swiftlint lint                    # Check all files), code:block14 (Presentation/) (+26 more)

### Community 6 - "Community 6"
Cohesion: 0.07
Nodes (8): MockAccountRepository, MockCardRepository, MockInstitutionRepository, MockTransactionImporter, MockTransactionRepository, DefaultTransactionImporter, InstitutionRepository, TransactionImporting

### Community 7 - "Community 7"
Cohesion: 0.08
Nodes (17): HDFCLineClassifier, BalanceDiscrepancy, ClassifiedLine, HDFCRawTransaction, ParseWarning, StatementLinePurpose, amountLine, balanceLine (+9 more)

### Community 8 - "Community 8"
Cohesion: 0.09
Nodes (9): AsyncParsableCommand, FinanceParserCLI, ParseCommand, HDFCPDFParser, Observation, PDFTextExtractor, VisionPDFTextExtractor, FinanceParsersTests (+1 more)

### Community 9 - "Community 9"
Cohesion: 0.1
Nodes (6): CSVStatementParser, TransactionBlock, HDFCTransactionReconstructor, PDFStatementParser, TXTStatementParser, StatementParser

### Community 10 - "Community 10"
Cohesion: 0.09
Nodes (15): ClassifiedLine, HDFCRawTransaction, StatementLinePurpose, amountLine, balanceLine, blank, dateLine, footer (+7 more)

### Community 11 - "Community 11"
Cohesion: 0.15
Nodes (4): Equatable, ParsedTransaction, StatementMetadata, TabularTransactionDecoder

### Community 12 - "Community 12"
Cohesion: 0.08
Nodes (24): Architecture, Build, code:bash (cd Packages/FinanceParsers), code:bash (python3 scripts/extract_hdfc_pdf.py statement.pdf), code:bash (python3 scripts/compare_parsers.py statement.pdf), code:bash (swift run FinanceParserCLI parse ~/Documents/statement.pdf), code:bash (swift test -v), code:bash (make parser-test          # Run tests) (+16 more)

### Community 13 - "Community 13"
Cohesion: 0.13
Nodes (12): CardRepository, Hashable, ImportView, MockCardRepository, TargetChoice, account, card, createAccount (+4 more)

### Community 14 - "Community 14"
Cohesion: 0.09
Nodes (12): ImportResult, StatementParser, TransactionImporting, InstitutionStatementParser, StatementSourceType, bankAccount, creditCard, AccountRepository (+4 more)

### Community 15 - "Community 15"
Cohesion: 0.17
Nodes (7): ParsedWorkbook, SharedStringsParserDelegate, WorksheetParserDelegate, XLSXStatementParser, XLSXWorkbookReader, NSObject, XMLParserDelegate

### Community 16 - "Community 16"
Cohesion: 0.1
Nodes (20): ALWAYS Read First, Architecture Rules, Build & Test Workflow, Change Scope Rules, code:bash (git rev-parse HEAD), code:bash (graphify update .), code:bash (git status), Coding Standards (+12 more)

### Community 17 - "Community 17"
Cohesion: 0.17
Nodes (4): HDFCMetadataExtractor, ScalarFields, String, Substring

### Community 18 - "Community 18"
Cohesion: 0.15
Nodes (10): Codable, FetchableRecord, StatementMetadata, Identifiable, Account, Bank, Card, Transaction (+2 more)

### Community 19 - "Community 19"
Cohesion: 0.12
Nodes (6): AmexStatementDetector, HDFCStatementDetector, ICICIStatementDetector, DetectedStatementMetadata, StatementDetector, StatementDetector

### Community 20 - "Community 20"
Cohesion: 0.14
Nodes (16): Architecture, Composition Root, Concrete Implementations, Core Rules, CSV, Current Modules, Database Handle, FinanceOS Architecture Rules (+8 more)

### Community 21 - "Community 21"
Cohesion: 0.18
Nodes (15): extract_debit_credit(), extract_text_lines(), find_table_start(), is_date_line(), main(), parse_amount(), parse_hdfc_transactions(), Heuristic: determine debit/credit from amounts.      For HDFC format: [debit, cr (+7 more)

### Community 22 - "Community 22"
Cohesion: 0.2
Nodes (7): DependencyChecker, DependencyStep, StepStatus, done, failed, pending, running

### Community 23 - "Community 23"
Cohesion: 0.13
Nodes (3): MockTransactionRepository, GRDBTransactionRepository, TransactionRepository

### Community 24 - "Community 24"
Cohesion: 0.23
Nodes (13): Current Architectural Constraints, Current Completed Features, Current Naming, Current Repositories, Current Risks, Current UI Flow, Database, Dependency Composition (+5 more)

### Community 25 - "Community 25"
Cohesion: 0.15
Nodes (11): CaseIterable, StatementFileFormat, csv, pdf, txt, xlsx, BankProviderType, bank (+3 more)

### Community 27 - "Community 27"
Cohesion: 0.2
Nodes (6): SupportedSourcesView, TargetSelectionSection, InstitutionEditView, View, TransactionFilterView, TransactionListContentView

### Community 29 - "Community 29"
Cohesion: 0.18
Nodes (3): Columns, Institution, DatabaseSeeder

### Community 31 - "Community 31"
Cohesion: 0.36
Nodes (7): analyze_differences(), main(), Run Swift CLI parser and return JSON output., Run Python reference parser and return JSON output., Compare transactions and identify differences., run_python_parser(), run_swift_parser()

### Community 32 - "Community 32"
Cohesion: 0.36
Nodes (7): extract_tables(), extract_text_with_positions(), main(), parse_hdfc_transactions(), Extract text preserving position information for table detection., Extract tables from PDF using pdfplumber's table detection., Parse HDFC transaction table into normalized format.      Handles pdfplumber's t

### Community 34 - "Community 34"
Cohesion: 0.25
Nodes (7): CardType, amex, mastercard, other, rupay, visa, Columns

### Community 35 - "Community 35"
Cohesion: 0.29
Nodes (8): DatabaseManager makeDatabaseURL, DatabaseManager migrator, DatabaseManager seedDatabase, DatabaseManager shared lifecycle, DatabaseSeeder seedInstitutions, Institution createTable, Institution Model, institutions SQLite Table

### Community 41 - "Community 41"
Cohesion: 0.33
Nodes (5): AccountType, credit, current, savings, Columns

### Community 45 - "Community 45"
Cohesion: 0.4
Nodes (4): Columns, TransactionType, credit, debit

## Knowledge Gaps
- **153 isolated node(s):** `Substring`, `csv`, `txt`, `xlsx`, `pdf` (+148 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **33 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `ImportView` connect `Community 13` to `Community 27`?**
  _High betweenness centrality (0.100) - this node is a cross-community bridge._
- **Why does `PDFStatementParser` connect `Community 9` to `Community 4`, `Community 14`?**
  _High betweenness centrality (0.096) - this node is a cross-community bridge._
- **Why does `ParsedStatement` connect `Community 0` to `Community 11`, `Community 14`?**
  _High betweenness centrality (0.058) - this node is a cross-community bridge._
- **Are the 22 inferred relationships involving `String` (e.g. with `.parseHDFCTransactions()` and `transactionHash()`) actually correct?**
  _`String` has 22 INFERRED edges - model-reasoned connections that need verification._
- **What connects `Substring`, `csv`, `txt` to the rest of the system?**
  _153 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Community 0` be split into smaller, more focused modules?**
  _Cohesion score 0.05 - nodes in this community are weakly interconnected._
- **Should `Community 1` be split into smaller, more focused modules?**
  _Cohesion score 0.04 - nodes in this community are weakly interconnected._
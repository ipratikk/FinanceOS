# FinanceOS
[![Build and Test](https://github.com/ipratikk/FinanceOS/actions/workflows/swift.yml/badge.svg)](https://github.com/ipratikk/FinanceOS/actions/workflows/swift.yml)

A native macOS financial management application for importing, analyzing, and tracking bank statements and credit card transactions with deterministic ingestion and deduplication.

## Features

- **Multi-Bank Statement Import** — CSV/TXT support for Indian banks (HDFC, ICICI, Amex)
- **Intelligent Deduplication** — Deterministic duplicate detection and merging across imports
- **Transaction Ledger** — Unified ledger view with accounts, tags, and filtering
- **Dashboard Analytics** — Net worth tracking, spending insights, and wealth intelligence
- **Design System** — Finance Design System (FDS) with consistent UI components and spacing
- **Parser Extensibility** — Bank-specific parsing rules with auto-format detection

## Getting Started

### Prerequisites

- **macOS 26+** (required for Swift 6.1 compatibility)
- **Xcode 26+** (required for Swift 6.1 toolchain)
- Swift 6.1+ (some packages require this version)

### Installation

1. Clone the repository:
```bash
git clone https://github.com/ipratikk/FinanceOS.git
cd FinanceOS
```

2. Run bootstrap (installs tools, seeds directories, sets up hooks):
```bash
bash bootstrap.sh
```

3. Open in Xcode:
```bash
open FinanceOS.xcworkspace
```

### Building & Running

Build using Claude Code skills or Make:

```bash
/build                    # SwiftUI app build
make parser-build         # Parser packages only
make parser-test          # Run parser tests
make parser-parse FILE=<path>  # Parse a single file
```

Or use Xcode directly:
```bash
xcodebuild -scheme FinanceOSMac -configuration Debug
```

## Project Structure

```
FinanceOS/
├── Apps/
│   └── FinanceOSMac/           # Native macOS app
│       └── GraphQL/            # Apollo codegen config, schema, generated types, Operations/*.graphql
├── Packages/
│   ├── FinanceCore/            # Models, GraphQL client, AppContainer, Logging, TransferEvent persistence (GRDB)
│   ├── FinanceParsers/         # Bank statement parsers, import pipeline, deduplicator
│   ├── FinanceUI/              # SwiftUI components & design system (FDS)
│   └── FinanceTesting/         # Shared test helpers, fixtures, golden JSON
├── Scripts/
│   ├── codegen.sh              # GraphQL schema fetch + Apollo codegen + build
│   ├── codegen-config.sh       # Per-environment GraphQL endpoint config
│   ├── fixtures/               # Golden JSON for parser validation
│   └── validate/               # pre-PR CI validation
├── docs/                       # Project documentation (see docs/ARCHITECTURE.md, docs/CODING_STANDARDS.md)
└── CLAUDE.md                   # Claude Code instructions
```

## Architecture

**SwiftUI View** → **ViewModel** → **ApolloGraphQLClient** → **financeos-backend (GraphQL API)**

FinanceOS is a GraphQL thin client. All bank/ledger/transaction data is owned by the
[financeos-backend](https://github.com/ipratikk/FinanceOS-Backend) service; the only local
persistence is `TransferEvent` (GRDB/SQLite), owned by `DatabaseManager`.

Key principles:
- Views never access the GraphQL client or repositories directly
- ViewModels call data via `ApolloGraphQLClient`, injected through `AppContainer`
- `DatabaseManager` owns local SQLite lifecycle (TransferEvent only)
- Parser layer isolated from UI/persistence

See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) for the full current-state breakdown.

## GraphQL Backend & Codegen

FinanceOS talks to [financeos-backend](https://github.com/ipratikk/FinanceOS-Backend) over GraphQL (`http://localhost:4000/graphql` locally, via Docker Compose).

Run the backend locally:
```bash
git clone https://github.com/ipratikk/FinanceOS-Backend.git
cd FinanceOS-Backend
./bootstrap.sh          # starts postgres, redis, node-api, python-parser via Docker Compose
```

Regenerate Swift GraphQL types after a backend schema change:
```bash
Scripts/codegen.sh [local|stage|prod]   # default: local
```

This fetches the schema via introspection, runs `apollo-ios-cli generate`, and builds the macOS target.
Config:
- Endpoints: [Scripts/codegen-config.sh](Scripts/codegen-config.sh)
- Apollo schema download config: [Apps/FinanceOSMac/GraphQL/apollo-schema-config.json](Apps/FinanceOSMac/GraphQL/apollo-schema-config.json)
- Apollo codegen config: [Apps/FinanceOSMac/GraphQL/apollo-codegen-config.json](Apps/FinanceOSMac/GraphQL/apollo-codegen-config.json)
- GraphQL operations: [Apps/FinanceOSMac/GraphQL/Operations/](Apps/FinanceOSMac/GraphQL/Operations/)

## Engineering Priorities

1. **Architectural Consistency** — Extend existing patterns, avoid new abstractions
2. **Deterministic Correctness** — Parser ingestion must be reproducible
3. **Low-Context Edits** — Incremental changes with clear scope
4. **Maintainability** — Explicit code over clever, long-term scalability
5. **Code Quality** — Max 120 char lines, 50-line functions, verified by SwiftLint

## Coding Standards

See [docs/CODING_STANDARDS.md](docs/CODING_STANDARDS.md) for detailed rules:

- **Line length:** 120 characters max
- **Functions:** 50 lines max
- **Types:** 250 lines max
- **Files:** 400 lines max
- **Linting:** All Swift files checked via `swiftlint lint`

## Development Workflow

### Before Committing

1. Run SwiftLint: `swiftlint lint`
2. Run tests: `swift test --parallel`
3. Build app: `/build`

### Creating a Pull Request

Use `/create-pr` skill (runs full CI pipeline):

```bash
/create-pr                     # Full validation
/create-pr --skipValidation    # Skip if already validated
```

Uses conventional commit format:
- `feat(scope): description`
- `fix(scope): description`
- `refactor(scope): description`
- `chore(scope): description`

### Code Review

- All PRs require review before merge
- CI must pass (SwiftLint, tests, build)
- Architecture decisions reviewed for coupling/impact

## CI/CD Pipeline

GitHub Actions workflow (`swift.yml`):

- **Runner:** macOS 26 (includes Swift 6.1+ pre-installed)
- **Change Detection:** Intelligent package dependency tracking
  - Single package change → test affected packages + dependents
  - Non-package change → test all packages for safety
- **Caching:** Multi-layer strategy (SPM, build artifacts, DerivedData, ModuleCache)
- **Validation Gate:** All jobs must pass before PR can merge

Performance:
- ~50% faster CI on single-package PRs (cached dependencies)
- Parallel package testing (4 tests in matrix)
- Shared dependency resolution across all jobs

## Testing

Run tests for individual packages:

```bash
cd Packages/FinanceCore && swift test --parallel
cd Packages/FinanceParsers && swift test --parallel
cd Packages/FinanceUI && swift test --parallel
```

Parser validation:

```bash
make parser-test               # Run all parser tests
make parser-parse FILE=path/to/statement.csv  # Parse single file
/parser-test                   # Claude Code skill
```

## Documentation

- **[CLAUDE.md](CLAUDE.md)** — Claude Code workflow and context
- **[docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)** — Current architecture, module ownership, data flow
- **[docs/AGENTS.md](docs/AGENTS.md)** — Agent routing and context-loading rules
- **[docs/CODING_STANDARDS.md](docs/CODING_STANDARDS.md)** — Code style rules
- **[docs/DESIGN_STANDARDS.md](docs/DESIGN_STANDARDS.md)** — UI/design system rules
- **[CONTRIBUTING.md](CONTRIBUTING.md)** — Contribution guide

## Current Focus

Phases 1–10 complete (Ledger unification, import pipeline, dedup engine, UI migration, MVVM/GraphQL refactor).

**Active: Financial Intelligence Platform** — transaction analysis, behavior detection, spending
insights. Intelligence logic is owned by [financeos-backend](https://github.com/ipratikk/FinanceOS-Backend)
(Python service); the category picker and filter UI wire to the `RecategorizeMutation` GraphQL endpoint.

Enablers:
- **Parser / Ingestion** — CSV/XLSX hardening, Indian banks, dedup, format detection
- **Card Catalog** — card metadata scraping moved to [financeos-backend](https://github.com/ipratikk/FinanceOS-Backend) (`card-scraper/`)

**Not implemented:**
- Sync across devices
- Pure ML training
- Cloud infrastructure
- AI chat features

## License

[MIT License](LICENSE) — See LICENSE file for details

## Code of Conduct

This project adheres to the [Contributor Covenant Code of Conduct](CODE_OF_CONDUCT.md).

## Security

For security vulnerabilities, see [SECURITY.md](SECURITY.md) for responsible disclosure.

## Support

- **Issues:** [GitHub Issues](https://github.com/ipratikk/FinanceOS/issues)
- **Discussions:** [GitHub Discussions](https://github.com/ipratikk/FinanceOS/discussions)

## Author

[Pratik Goel](https://github.com/ipratikk) — *Senior Software Engineer focused on architecture, deterministic systems, and long-term maintainability.*

---

**Status:** Active development  
**Last Updated:** 2026-07-05

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
├── Packages/
│   ├── FinanceCore/            # Models, repositories, persistence (GRDB)
│   ├── FinanceParsers/         # Bank statement parsers
│   ├── FinanceUI/              # SwiftUI components & design system
│   └── FinanceTesting/         # Shared test helpers & fixtures
├── Scripts/
│   ├── fixtures/               # Golden JSON for parser validation
│   └── validate/               # pre-PR CI validation
├── docs/                       # Project documentation
├── CLAUDE.md                   # Claude Code instructions
└── CODING_STANDARDS.md         # Code style & linting rules
```

## Architecture

**View Layer** → **ViewModel** → **Repository Protocol** → **GRDB Repository** → **SQLite**

Key principles:
- Views never access database directly
- ViewModels don't contain SQL
- Repositories encapsulate persistence
- Parser layer isolated from UI/persistence

## Engineering Priorities

1. **Architectural Consistency** — Extend existing patterns, avoid new abstractions
2. **Deterministic Correctness** — Parser ingestion must be reproducible
3. **Low-Context Edits** — Incremental changes with clear scope
4. **Maintainability** — Explicit code over clever, long-term scalability
5. **Code Quality** — Max 120 char lines, 50-line functions, verified by SwiftLint

## Coding Standards

See [CODING_STANDARDS.md](CODING_STANDARDS.md) for detailed rules:

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
- **[CODING_STANDARDS.md](CODING_STANDARDS.md)** — Code style rules
- **[CONTRIBUTING.md](CONTRIBUTING.md)** — Contribution guide
- **[docs/](docs/)** — Project documentation

## Current Focus (Phase 10+)

1. CSV/TXT parser hardening (additional Indian banks)
2. Statement format auto-detection
3. Bank-specific parsing rules
4. Duplicate detection at scale
5. Analytics and spending insights

**Not implemented:**
- Sync across devices
- ML-based categorization
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
**Last Updated:** 2026-05-22

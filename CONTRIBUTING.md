# Contributing to FinanceOS

Thank you for your interest in contributing to FinanceOS! This document provides guidelines and instructions for contributing code, documentation, and bug reports.

## Code of Conduct

Please review and adhere to our [Code of Conduct](CODE_OF_CONDUCT.md). We are committed to providing a welcoming and inclusive environment.

## Getting Started

### Development Setup

1. Clone the repository and navigate to the project:
```bash
git clone https://github.com/ipratikk/FinanceOS.git
cd FinanceOS
```

2. Run the bootstrap script (one-time setup):
```bash
bash bootstrap.sh
```

This installs:
- Xcode command line tools
- SwiftLint for code linting
- Build dependencies
- Git hooks for pre-commit validation
- Project directories

3. Open the workspace:
```bash
open FinanceOS.xcworkspace
```

### Running Tests & Validation

Before opening a PR, ensure your code passes:

```bash
# Run all tests
swift test --parallel

# Run parser tests specifically
make parser-test

# Lint Swift code
swiftlint lint

# Build the macOS app
/build
```

Or use the comprehensive pre-PR validation:

```bash
/create-pr        # Runs SwiftLint, tests, and build — stops on failure
```

## Contribution Types

### Bug Reports

Found a bug? Create an issue using the [bug report template](.github/ISSUE_TEMPLATE/bug_report.md):

1. **Describe the bug** — What happened?
2. **Steps to reproduce** — How to recreate it
3. **Expected behavior** — What should happen
4. **Environment** — macOS version, Xcode version, app version
5. **Screenshots/logs** — If applicable

### Feature Requests

Have an idea? Create an issue using the [feature request template](.github/ISSUE_TEMPLATE/feature_request.md):

1. **Description** — What's the feature?
2. **Motivation** — Why is it useful?
3. **Proposed solution** — How would it work?
4. **Alternatives** — Any other approaches?

### Code Changes

#### Branch Naming

Use descriptive branch names following the pattern:

```
<type>/<description>
```

Types:
- `feat/` — New feature
- `fix/` — Bug fix
- `refactor/` — Code refactoring
- `chore/` — Build, dependencies, documentation
- `test/` — Tests or test infrastructure

Examples:
- `feat/hdfc-csv-parser`
- `fix/duplicate-detection-edge-case`
- `refactor/repository-layer`
- `chore/update-dependencies`

#### Commit Messages

Follow Conventional Commits format:

```
<type>(<scope>): <description>

<optional body>

<optional footer>
```

**Type:** `feat`, `fix`, `refactor`, `chore`, `test`, `docs`  
**Scope:** Package or component name (e.g., `parsers`, `dashboard`, `fds`)  
**Description:** Imperative mood, lowercase, no period

Example:
```
feat(parsers): add HDFC CSV format detection

Implements auto-detection for HDFC bank statement CSV format
by checking column headers and date formats. Falls back to
manual format selection if auto-detection fails.

Closes #42
```

#### Creating a Pull Request

1. **Sync with main:**
```bash
git fetch origin
git rebase origin/main
```

2. **Create the PR using Claude Code skill:**
```bash
/create-pr
```

This will:
- ✓ Validate branch naming
- ✓ Run SwiftLint, tests, and build
- ✓ Sync with main if behind
- ✓ Create PR with proper formatting

3. **Fill in the PR template** (auto-generated):

```markdown
## Summary
- What changed
- Why it changed

## Test plan
- [ ] Manual testing done
- [ ] Tests added/updated
- [ ] No regressions observed

## Notes
- Any breaking changes
- Migration steps
- Design decisions
```

### Code Style & Standards

FinanceOS enforces strict code quality standards. All code must:

1. **Pass SwiftLint** — Zero violations in strict mode
   ```bash
   swiftlint lint
   ```

2. **Follow line length limits:**
   - Max 120 characters per line
   - Exceptions: imports, URLs (documented in `.swiftlint.yml`)

3. **Follow size limits:**
   - Functions: max 50 lines
   - Types: max 250 lines
   - Files: max 400 lines

4. **Use explicit, predictable code:**
   - Avoid clever abstractions
   - Prefer clarity over conciseness
   - Document non-obvious "why"

5. **Adhere to architecture:**
   - Views don't access database
   - ViewModels don't contain SQL
   - Repositories encapsulate persistence

See [CODING_STANDARDS.md](CODING_STANDARDS.md) for complete guidelines.

## Architecture & Design Decisions

### When to Ask Before Coding

Before starting major work, discuss:

1. **Cross-module changes** — Impact analysis needed
2. **New abstractions** — Extension vs. refactor decision
3. **Architecture violations** — View/VM/Repo layer boundaries
4. **Parser infrastructure changes** — Determinism critical
5. **API changes** — Backward compatibility concerns

### Key Principles

- **Architectural Consistency** — Extend patterns, don't invent
- **Deterministic Correctness** — Parsers must be reproducible
- **Incremental Edits** — Low-context changes preferred
- **Maintainability** — Long-term scalability over speed
- **Explicit Code** — Clarity > cleverness

## Review Process

1. **Automated checks must pass:**
   - SwiftLint
   - Unit tests
   - macOS build

2. **Code review:**
   - One approval required
   - Architecture decisions reviewed
   - No unnecessary refactoring mixed with features

3. **Merge:**
   - Squash commits (one commit per feature)
   - Use conventional commit message
   - Delete branch after merge

## Project Structure Context

Understanding the architecture helps contribute effectively:

```
Packages/
├── FinanceCore/          # Models, DB, repositories
├── FinanceParsers/       # Bank statement parsers
├── FinanceUI/            # SwiftUI components, design system
└── FinanceTesting/       # Shared test fixtures

Apps/
└── FinanceOSMac/         # Native macOS application
```

**View → ViewModel → Repository → GRDB → SQLite**

- Views use `@ObservedObject` ViewModels
- ViewModels delegate persistence to Repository protocols
- Repositories use GRDB for SQLite access
- Parsers transform statements to domain models

## Testing Guidelines

### Unit Tests

- Test public APIs and repositories
- Mock external dependencies
- Use golden JSON for parser validation

### Parser Tests

- Compare output against `Scripts/fixtures/golden.json`
- Test both happy path and edge cases
- Document format variations

Run tests:
```bash
make parser-test               # All parsers
make parser-parse FILE=<path>  # Single file validation
```

### Manual Testing

For UI changes:
1. Build the app: `xcodebuild -scheme FinanceOSMac`
2. Test affected screens
3. Test responsive layouts
4. Document in PR

## Documentation

Good documentation is part of contribution quality:

- **Code comments** — Only "why", not "what"
- **PR descriptions** — Summarize changes, link issues
- **README updates** — If you change public APIs
- **Commit messages** — Clear intent and context

## Performance & Security

### Performance Considerations

- Parser must handle large files (100MB+ statements)
- UI must remain responsive during imports
- Database queries should be indexed
- Consider memory efficiency for batch operations

### Security

- No credentials in code or commits
- Sanitize file paths and user input
- Use HTTPS for any external connections
- See [SECURITY.md](SECURITY.md) for vulnerability reporting

## Getting Help

- **Questions?** Open a discussion or issue
- **Stuck?** Comment on related issue or PR
- **Architecture help?** Open issue with `architecture` label
- **Design feedback?** Request review from maintainer

## Recognition

Contributors are recognized in:
- PR acknowledgment comments
- Release notes (for significant contributions)
- Project contributors list (README)

## License

By contributing, you agree that your contributions will be licensed under the project's [MIT License](LICENSE).

---

Thank you for helping make FinanceOS better! 🎉

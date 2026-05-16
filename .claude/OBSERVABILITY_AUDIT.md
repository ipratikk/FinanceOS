# FinanceOS Observability & Error Handling Audit

## Executive Summary

Current state: **Observability is minimal, error handling is inconsistent, and async flows are not traceable.**

- **Total logging statements in FinanceCore**: 6 calls
- **Critical paths without logs**: 95%+ of import, repository, and database operations
- **Silent failures**: 3 try? calls without recovery logging
- **Correlation ID system**: None (impossible to trace async operations)
- **Structured logging**: None (metadata mixed into messages)
- **Performance metrics**: None
- **Error categorization**: Incomplete (only parsing errors defined)
- **User message separation**: Missing (technical errors not isolated)

---

## 1. Current Logging Coverage

### Existing Logs (6 total)

**Database/Migration (5 logs)**
- AppMigration.swift: 5 migration-level logs
  - v1-v8 migration start logs
  - v8 error and success logs

**Database Init (1 log)**
- DatabaseManager.swift: Database URL initialization

**Seeding (1 log)**
- DatabaseSeeder.swift: Seeding summary

### Missing Logs

**Import Pipeline**: Zero logs
- Parser selection
- File parsing start/end
- File duration
- Account matching
- Transaction count
- Duplicate detection
- Import commit/rollback

**Repositories**: Zero logs
- Transaction insert counts
- Query execution
- Constraint violations
- Update/delete operations

**Parsing**: Zero logs
- Detection results
- Parser-specific metadata
- Validation failures
- Metadata extraction

**Database**: Zero logs beyond migration
- Transaction boundaries
- Constraint enforcement
- Rollback triggers
- Corruption detection

**Services**: Zero logs
- Filename extraction
- Account matching

**Error boundaries**: Zero logs
- Catch block entries
- Error context
- Recovery attempts
- Retry decisions

---

## 2. Silent Failures

### try? Calls (3 found)

**FilenameMetadataExtractor.swift**
```swift
if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive)
if let regex = try? NSRegularExpression(pattern: pattern)
if let regex = try? NSRegularExpression(pattern: pattern)
```
- Silently fails if regex creation fails
- No logging, no recovery attempt
- Cascades as nil, may cause downstream issues

**Risk**: Malformed patterns cause silent feature degradation.

---

## 3. Error Handling Gaps

### Incomplete Error Hierarchy

**Defined errors:**
- TransactionImportError (FinanceParsers) - 8 cases
- DetectionError (FinanceParsers) - missing review
- DatabaseError (GRDB) - external

**Missing categories:**
- Repository errors (CRUD failures, constraint violations)
- Database errors beyond GRDB (migration failures, state corruption)
- Validation errors (data quality, bounds)
- File access errors (permissions, missing files)
- Account matching errors (ambiguous accounts)
- Sync errors (future)
- Network errors (future)

### Error Propagation Issues

**ImportViewModel.swift** (lines 117-129)
- Catches specific error types but not all possible failures
- Logs basic error description but not context
- No logging before throwing (error swallowed if not caught)
- No correlation ID for tracing this import session

**GRDBTransactionRepository.swift** (lines 61-67)
- Silently skips duplicate transactions (SQLITE_CONSTRAINT)
- No logging of which transaction was skipped
- No metadata about why it was a duplicate
- ImportResult reports counts but not reasons

**AppMigration.swift** (lines 239-303)
- Catches errors and logs
- But doesn't log migration stage/context details
- Doesn't log transaction boundaries
- Doesn't log pre-failure state

---

## 4. Missing Context in Current Logs

### Message Quality Issues

Current logs are bare:
```
"Running migration: v7_ledger_unification"
"Database initialized at: /path/to/db"
"Parsed {file}: {count} txns from {bank}"
```

Missing from logs:
- Import session identifier
- Operation duration
- Success/failure state
- Previous state
- Rollback information
- Account/transaction identifiers (privacy-safe versions)
- Operation timing
- Retry/backoff attempts

---

## 5. Async Flow Traceability

### Current State

Zero correlation across async boundaries:
- parseFiles() → parseFile() → StatementDetector.detect() → UnifiedStatementParser.parse()
  - No way to correlate logs across these async calls
  - If parser fails, unclear which file failed
  - If import fails after parsing, unclear which parsed statement caused it

### Problem

If an import fails at any stage:
- No trace ID to query all logs for this import
- No way to reconstruct the exact file/statement/target
- No way to determine if rollback occurred
- No duration metrics
- No visibility into success/failure path

---

## 6. Print Statements (2 found)

**Components/EmptyStateView.swift**
```swift
action: { print("Import") }
```

**Components/SectionHeader.swift**
```swift
action: { print("View All") }
```

- Debug placeholders left in code
- Should be removed or replaced with proper logging

---

## 7. Log Level Usage

### Current State

- All existing logs use `.info()` or `.error()`
- No distinction of:
  - Trace (developer debugging)
  - Debug (detailed state changes)
  - Notice (unusual but expected)
  - Warning (potential issues)
  - Critical (system integrity)

### Required Levels

All critical paths need proper level assignment:
- **Trace**: Detailed execution flow (regex matching, metadata extraction)
- **Debug**: State changes, transitions (target selection, parsing stage)
- **Info**: Significant boundaries (import start/end, migration version)
- **Notice**: Unusual patterns (duplicate detected, account not found)
- **Warning**: Degraded operation (parser fallback, metadata missing)
- **Error**: Operation failure (parse failed, import rolled back)
- **Critical**: System integrity (migration failure, database corruption)

---

## 8. Privacy & Security

### Current State

Logs are generally safe but inconsistent:
- URLs logged (acceptable)
- File counts logged (safe)
- Transaction counts logged (safe)
- Error descriptions logged (may contain filename)

### Risks

Not logged, but should never be:
- Account numbers
- Card numbers
- Transaction details (merchant, description)
- Balance amounts
- Customer names
- Email/phone

Current code avoids these, but no formal privacy policy enforced.

---

## 9. Error Presentation Architecture

### Current State

Errors converted to strings in UI:
```swift
importSession.errorMessage = "Error parsing \(fileURL.lastPathComponent): \(error.userMessage)"
```

### Problems

- Technical errors mixed with user messages
- No recovery actions exposed
- No retry logic
- No categorization of retryable vs. permanent failures

### Required

Separate technical error (logged fully) from user message:
- Technical: "SQLITE_CONSTRAINT on transactions(ledgerId, sourceFingerprint)"
- User: "This statement appears to already have been imported."

---

## 10. Performance Metrics

### Missing

No tracking of:
- Parse duration by parser
- Total import duration
- Account matching duration
- DB insert batch duration
- File I/O duration
- JSON parsing duration

### Impact

Can't identify bottlenecks or performance regressions.

---

## 11. Database Operation Logging

### Missing

**Migrations**
- Start timestamp
- Version
- SQL executed
- Rollback trigger points
- Duration
- Previous schema state

**Transactions**
- Insert count
- Skipped count (with reasons)
- Update count
- Constraint violation details

**Queries**
- Duration
- Row count returned
- Index usage hints
- Blocking operations

### Current

Only migration start/end logs, no details.

---

## 12. Repository Layer Insights

### Missing

**GRDBTransactionRepository.insertTransactions()**
- What transaction was skipped (not just count)
- Why it was a duplicate (fingerprint match)
- Which ledger it targeted
- Total vs. inserted vs. skipped breakdown

**GRDBLedgerRepository** (assumed similar)
- No visibility into CRUD operations
- No query duration
- No constraint violations

---

## Recommendations (Next Phases)

### Phase 2: Architecture Design
- Logger categories (ui, accounts, transactions, parsing, importPipeline, database, repository, sync, security, performance)
- Log level helpers (logTrace, logDebug, logInfo, logNotice, logWarning, logError, logCritical)
- Correlation ID system (OperationContext)
- Structured logging metadata pattern
- Error hierarchy (FinanceError protocol)
- Error categorization (Parsing, Import, Database, Validation, etc.)
- User message mapping (technical → user-friendly)
- Performance timer utility
- Privacy-safe logging annotations

### Phase 3: Logger System Implementation
- Expand FinanceLogger with all categories
- Implement log level helpers
- Add structured metadata support
- Privacy markers for sensitive fields

### Phase 4: Error System Implementation
- FinanceError protocol
- Error categories
- User message generation
- Error mapping utilities
- Tests for error behavior

### Phase 5-10: Instrumentation & Fixes
- Import pipeline (every stage)
- Repository operations (CRUD counts/durations)
- Database operations (migrations, transactions)
- Parser operations (detection, validation)
- Silent failure fixes
- Performance tracking
- UI error presentation
- Comprehensive tests

---

## Key Metrics for Success

After refactor, we must be able to answer:

**Import Failure**
- ✅ Which file failed (filename, path, size)
- ✅ Which parser was used
- ✅ At which stage (detection, parsing, matching, insertion)
- ✅ What was the exact error
- ✅ Was it retryable
- ✅ Was rollback attempted
- ✅ How long did it take

**Database State**
- ✅ How many migrations ran on startup
- ✅ How many ledgers exist
- ✅ How many transactions inserted today
- ✅ How many duplicates detected
- ✅ Any constraint violations

**Performance**
- ✅ Parse duration per file
- ✅ Import duration per batch
- ✅ Database insert performance
- ✅ Query execution times
- ✅ File I/O bottlenecks

**Error Distribution**
- ✅ Most common parse errors
- ✅ Most common import errors
- ✅ Retryable vs. permanent
- ✅ User impact vs. developer-only

---

## Implementation Priority

1. **High**: Logger system, correlation IDs (enables all other improvements)
2. **High**: Error hierarchy (required for categorization)
3. **High**: Import pipeline instrumentation (highest value for debugging)
4. **High**: Silent failure fixes (correctness)
5. **Medium**: Repository logging (operational visibility)
6. **Medium**: Database logging (operational visibility)
7. **Medium**: Performance tracking (optimization data)
8. **Low**: SwiftUI error presentation (user experience)

---

## Files to Modify (Phase 1 Output)

### Create
- Logging/OperationContext.swift (correlation IDs)
- Logging/PerformanceTimer.swift (performance tracking)
- Logging/StructuredLogMetadata.swift (metadata handling)
- Errors/FinanceError.swift (error protocol)
- Errors/ErrorCategoryMapping.swift (error categorization)
- Utilities/ErrorPresentation.swift (UI error model)

### Modify
- Logging/FinanceLogger.swift (expand categories, add levels)
- Database/AppMigration.swift (add stage logging)
- Database/DatabaseManager.swift (add lifecycle logging)
- Repositories/GRDBTransactionRepository.swift (log CRUD operations)
- Repositories/GRDBLedgerRepository.swift (log CRUD operations)
- Repositories/GRDBBankRepository.swift (log CRUD operations)
- Importing/TransactionImportPipeline.swift (add instrumentation)
- Services/FilenameMetadataExtractor.swift (fix silent failures)
- Components/EmptyStateView.swift (remove print)
- Components/SectionHeader.swift (remove print)

### Review & Enhance
- ImportViewModel.swift (error context, correlation ID)
- All error throwing functions (add logging before throw)
- All async boundaries (correlation ID propagation)


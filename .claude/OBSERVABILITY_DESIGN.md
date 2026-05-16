# FinanceOS Observability Architecture Design

## Overview

Three core systems:
1. **Structured Logging** - categories, levels, metadata, correlation
2. **Error Hierarchy** - categorization, user messages, recovery hints
3. **Performance Tracking** - durations, bottleneck identification

---

## Part 1: Structured Logging Architecture

### 1.1 Logger Categories

```swift
public enum FinanceLogger {
    public static let ui = Logger(...)              // SwiftUI views, navigation
    public static let accounts = Logger(...)        // Ledger CRUD, queries
    public static let transactions = Logger(...)    // Transaction CRUD, queries
    public static let importPipeline = Logger(...)  // Import orchestration
    public static let parsing = Logger(...)         // File parsing, detection
    public static let database = Logger(...)        // DB init, migrations
    public static let repository = Logger(...)      // Repository operations
    public static let performance = Logger(...)     // Timing, metrics
    public static let sync = Logger(...)            // Sync operations (future)
    public static let security = Logger(...)        // Auth, validation
    
    private static let subsystem = "com.pratik.FinanceOS"
}
```

**Rationale:**
- ui: View layer events (navigation, state changes)
- accounts: Ledger domain operations
- transactions: Transaction domain operations
- importPipeline: Import orchestration, not parsing
- parsing: File parsing details
- database: Lifecycle, migrations, constraints
- repository: CRUD operations, query results
- performance: Durations, metrics
- security: Auth, validation, constraints
- sync: Separate from import for future expansion

### 1.2 Log Levels

Implement extension on Logger:

```swift
public extension Logger {
    func logTrace(
        _ message: StaticString,
        _ metadata: [String: CustomStringConvertible] = [:]
    )
    
    func logDebug(
        _ message: StaticString,
        _ metadata: [String: CustomStringConvertible] = [:]
    )
    
    func logInfo(
        _ message: StaticString,
        _ metadata: [String: CustomStringConvertible] = [:]
    )
    
    func logNotice(
        _ message: StaticString,
        _ metadata: [String: CustomStringConvertible] = [:]
    )
    
    func logWarning(
        _ message: StaticString,
        _ metadata: [String: CustomStringConvertible] = [:]
    )
    
    func logError(
        _ message: StaticString,
        _ metadata: [String: CustomStringConvertible] = [:]
    )
    
    func logCritical(
        _ message: StaticString,
        _ metadata: [String: CustomStringConvertible] = [:]
    )
}
```

**Level Semantics:**
- **Trace**: Verbose execution flow (regex tests, option parsing)
- **Debug**: State changes, transitions (file opened, target selected)
- **Info**: Significant boundaries (import started, migration ran)
- **Notice**: Unusual but expected (duplicate detected, fallback used)
- **Warning**: Degraded operation (metadata missing, parser fallback)
- **Error**: Operation failure (parse error, import failed)
- **Critical**: System integrity compromised (migration failed, DB corruption)

**Implementation Pattern:**
```swift
var msg = staticMsg.withUTF8Buffer { String(decoding: $0, as: UTF8.self) }
for (key, value) in metadata {
    msg = msg.replacingOccurrences(of: "{\(key)}", with: String(describing: value))
}
debug("\(msg, privacy: .public)")
```

---

### 1.3 Correlation ID System

**OperationContext.swift:**

```swift
public struct OperationContext: Sendable {
    public let id: String  // UUID-based operation ID
    public let name: String  // Human-readable operation name
    public let startTime: Date
    
    public static func importSession() -> OperationContext {
        OperationContext(
            id: UUID().uuidString,
            name: "import",
            startTime: Date()
        )
    }
    
    public static func parseFile(fileName: String) -> OperationContext {
        OperationContext(
            id: UUID().uuidString,
            name: "parse:\(fileName)",
            startTime: Date()
        )
    }
}

// Thread-local / Actor-isolated storage
@MainActor
public class ContextStack {
    private var stack: [OperationContext] = []
    
    public func push(_ context: OperationContext) {
        stack.append(context)
    }
    
    public func pop() {
        if !stack.isEmpty {
            stack.removeLast()
        }
    }
    
    public var current: OperationContext? {
        stack.last
    }
}
```

**Usage Pattern:**

```swift
func importTransactions() {
    let context = OperationContext.importSession()
    let contextStack = ContextStack()
    contextStack.push(context)
    
    defer { contextStack.pop() }
    
    logger.logInfo(
        "Import started",
        ["sessionId": context.id, "target": target.description]
    )
    
    do {
        try await performImport()
        logger.logInfo(
            "Import completed",
            ["sessionId": context.id, "duration": Date().timeIntervalSince(context.startTime)]
        )
    } catch {
        logger.logError(
            "Import failed",
            ["sessionId": context.id, "error": error.localizedDescription]
        )
    }
}
```

**Benefit:** All logs within async block automatically include sessionId.

---

### 1.4 Structured Metadata

**Pattern:**

Bad:
```swift
logger.info("Parsed file \(fileName) with \(count) transactions")
```

Good:
```swift
logger.logInfo(
    "Parsed file {fileName} with {txnCount} txns from {bank}",
    [
        "fileName": fileName,
        "txnCount": count,
        "bank": statement.bankName,
        "sessionId": context.id,
        "duration": duration
    ]
)
```

**Required Metadata by Domain:**

**Import Pipeline**
- sessionId: OperationContext.id
- fileIndex: 1 of 5
- fileName: statement.pdf
- parser: HDFCPDFParser
- bankName: HDFC
- txnCount: 42
- duration: 1.23s
- stage: parsing | matching | inserting | committing

**Parsing**
- fileName: statement.pdf
- format: pdf
- bankName: HDFC
- result: success | failure
- txnCount: 42
- metadataExtracted: true
- duration: 1.23s

**Repository Operations**
- operation: insert | update | delete | query
- entity: transaction | ledger | bank
- count: 42
- duration: 0.34s
- error: (if failed)

**Database**
- version: v8
- migration: ledger_cascade_delete
- result: success | failure | rollback
- duration: 0.12s

---

### 1.5 Privacy-Safe Logging

**Policy:**

Never log:
- Full account/card numbers
- Full balances
- Full transaction descriptions (merchant, payee)
- Customer names
- Email addresses
- Phone numbers
- Raw statement content

Safe to log:
- Last 4 digits of accounts/cards
- Transaction counts
- Statement date ranges
- Bank names
- Parser names
- File paths/names
- Account types (checking, credit, etc.)
- Currency
- Error types (without sensitive context)

**Annotation Pattern:**

```swift
logger.logInfo(
    "Imported {txnCount} txns to ledger {ledgerId}",
    [
        "txnCount": result.inserted,
        "ledgerId": target.ledgerId.uuidString,  // Safe: UUID only
        "ledgerLast4": ledger.last4,              // Safe: last 4 only
        "bank": ledger.bankName                   // Safe: public info
    ]
)
```

---

## Part 2: Error Hierarchy

### 2.1 FinanceError Protocol

```swift
public protocol FinanceError: LocalizedError {
    /// Error category for routing, logging, metrics
    var category: ErrorCategory { get }
    
    /// Severity level for alerting thresholds
    var severity: ErrorSeverity { get }
    
    /// Technical error message (logged fully, never shown to user)
    var technicalMessage: String { get }
    
    /// User-friendly message (shown in UI)
    var userMessage: String { get }
    
    /// Recovery suggestion (e.g., "Check file format and try again")
    var recoverySuggestion: String? { get }
    
    /// Whether this error can succeed on retry
    var isRetryable: Bool { get }
    
    /// Optional underlying error for context
    var underlyingError: Error? { get }
}

public enum ErrorCategory: String, Sendable {
    case parsing        // File format, structure
    case import         // Import orchestration
    case database       // SQLite, GRDB, schema
    case validation     // Data quality, bounds
    case repository     // CRUD, query
    case fileAccess     // Permissions, missing files
    case matching       // Account/ledger matching
    case sync           // Future
    case network        // Future
    case unknown
}

public enum ErrorSeverity: String, Sendable {
    case info           // Expected error, user can recover
    case warning        // Degraded operation, user should check
    case error          // Operation failed, requires user action
    case critical       // System integrity compromised
}
```

### 2.2 Error Implementations

**Parsing Errors:**

```swift
public enum ParsingError: FinanceError {
    case unsupportedFormat(String)
    case missingColumn(String)
    case invalidDate(String, pattern: String)
    case invalidAmount(String)
    case malformedStructure(String)
    
    public var category: ErrorCategory { .parsing }
    
    public var severity: ErrorSeverity {
        switch self {
        case .unsupportedFormat, .missingColumn: return .error
        case .invalidDate, .invalidAmount: return .warning
        case .malformedStructure: return .error
        }
    }
    
    public var technicalMessage: String {
        switch self {
        case let .unsupportedFormat(format):
            return "Parser not available for format: \(format)"
        case let .missingColumn(col):
            return "Required column missing: \(col)"
        // ... etc
        }
    }
    
    public var userMessage: String {
        switch self {
        case let .unsupportedFormat(format):
            return "File format '\(format)' is not supported. Try CSV, XLSX, or PDF."
        case let .missingColumn(col):
            return "Statement is missing required column: \(col)"
        case let .invalidDate(value, _):
            return "Date '\(value)' is not in expected format."
        // ... etc
        }
    }
    
    public var recoverySuggestion: String? {
        "Check the file format and try again. Contact support if the error persists."
    }
    
    public var isRetryable: Bool {
        false  // File format errors are permanent
    }
}
```

**Import Errors:**

```swift
public enum ImportError: FinanceError {
    case nFilesSelected
    case noTargetSelected
    case targetNotFound(UUID)
    case duplicateDetected(count: Int)
    case rollbackRequired(reason: String)
    case commitFailed(reason: String)
    
    public var category: ErrorCategory { .import }
    
    public var severity: ErrorSeverity {
        switch self {
        case .duplicateDetected: return .info
        case .nFilesSelected, .noTargetSelected: return .warning
        case .targetNotFound, .rollbackRequired, .commitFailed: return .error
        }
    }
    
    public var technicalMessage: String {
        // Full details for logging
    }
    
    public var userMessage: String {
        switch self {
        case .nFilesSelected:
            return "Please select at least one file to import."
        case .noTargetSelected:
            return "Please select which account to import into."
        case let .duplicateDetected(count):
            return "\(count) transaction(s) were already imported and skipped."
        case let .rollbackRequired(reason):
            return "Import failed and was rolled back. Reason: \(reason)"
        // ... etc
        }
    }
    
    public var isRetryable: Bool {
        switch self {
        case .nFilesSelected, .noTargetSelected, .duplicateDetected:
            return false
        case .commitFailed:
            return true  // Temporary DB lock, retry may succeed
        // ... etc
        }
    }
}
```

**Database Errors:**

```swift
public enum DatabaseError: FinanceError {
    case migrationFailed(version: String, reason: String)
    case constraintViolation(table: String, constraint: String)
    case queryFailed(sql: String, reason: String)
    case corruptionDetected(description: String)
    
    public var category: ErrorCategory { .database }
    
    public var severity: ErrorSeverity {
        switch self {
        case .constraintViolation:
            return .warning
        case .queryFailed:
            return .error
        case .migrationFailed, .corruptionDetected:
            return .critical
        }
    }
    
    public var technicalMessage: String {
        // Full SQL, GRDB error details
    }
    
    public var userMessage: String {
        switch self {
        case .constraintViolation:
            return "This data conflicts with existing records. The import was skipped."
        case .queryFailed:
            return "Database operation failed. Please try again or restart the app."
        case .migrationFailed:
            return "Database update failed. Please restart the app or contact support."
        case .corruptionDetected:
            return "Database is corrupted. Please contact support."
        }
    }
}
```

### 2.3 Error Mapping

**ErrorMapper.swift:**

```swift
public enum ErrorMapper {
    /// Convert unknown Error to FinanceError
    public static func map(_ error: Error) -> FinanceError {
        if let financeError = error as? FinanceError {
            return financeError
        }
        
        if let dbError = error as? GRDB.DatabaseError {
            return mapDatabaseError(dbError)
        }
        
        if let decodingError = error as? DecodingError {
            return mapDecodingError(decodingError)
        }
        
        // Default to unknown
        return UnknownError(underlying: error)
    }
    
    private static func mapDatabaseError(_ error: GRDB.DatabaseError) -> FinanceError {
        switch error.resultCode {
        case .SQLITE_CONSTRAINT:
            return DatabaseError.constraintViolation(
                table: "unknown",
                constraint: error.message ?? "unknown"
            )
        case .SQLITE_IOERR:
            return DatabaseError.queryFailed(
                sql: "unknown",
                reason: error.message ?? "I/O error"
            )
        default:
            return DatabaseError.queryFailed(
                sql: "unknown",
                reason: error.message ?? "Unknown error"
            )
        }
    }
    
    private static func mapDecodingError(_ error: DecodingError) -> FinanceError {
        return ParsingError.malformedStructure(
            String(describing: error)
        )
    }
}

public struct UnknownError: FinanceError {
    public let underlying: Error
    
    public var category: ErrorCategory { .unknown }
    public var severity: ErrorSeverity { .error }
    public var technicalMessage: String { String(describing: underlying) }
    public var userMessage: String { "An unexpected error occurred." }
    public var recoverySuggestion: String? { "Please try again or contact support." }
    public var isRetryable: Bool { false }
    public var underlyingError: Error? { underlying }
}
```

---

## Part 3: Performance Tracking

### 3.1 PerformanceTimer Utility

```swift
public struct PerformanceTimer: Sendable {
    private let logger: Logger
    private let operation: String
    private let metadata: [String: CustomStringConvertible]
    private let startTime: Date
    
    public init(
        logger: Logger,
        operation: String,
        metadata: [String: CustomStringConvertible] = [:]
    ) {
        self.logger = logger
        self.operation = operation
        self.metadata = metadata
        self.startTime = Date()
    }
    
    public func mark(_ stage: String) {
        let duration = Date().timeIntervalSince(startTime)
        var allMetadata = metadata
        allMetadata["operation"] = operation
        allMetadata["stage"] = stage
        allMetadata["duration"] = String(format: "%.3fs", duration)
        
        logger.logDebug(
            "{operation} stage {stage} took {duration}",
            allMetadata
        )
    }
    
    public func complete(result: String = "success") {
        let duration = Date().timeIntervalSince(startTime)
        var allMetadata = metadata
        allMetadata["operation"] = operation
        allMetadata["duration"] = String(format: "%.3fs", duration)
        allMetadata["result"] = result
        
        let level: OSLogType = result == "success" ? .info : .error
        logger.logInfo(
            "{operation} completed in {duration}: {result}",
            allMetadata
        )
    }
}

// Usage
let timer = PerformanceTimer(
    logger: FinanceLogger.importPipeline,
    operation: "parseFile",
    metadata: ["fileName": fileName]
)
defer { timer.complete() }

timer.mark("detection")
let detected = try await detect(file)

timer.mark("parsing")
let parsed = try await parse(file, detected)

timer.mark("matching")
let matched = try await match(parsed)
```

---

## Part 4: Integration Points

### 4.1 Import Pipeline Flow

```
parseFiles()
├─ [import-session-123] Import started, 3 files
├─ parseFile(statement.pdf)
│  ├─ [parse-session-123-1] Parse started
│  ├─ [parse-session-123-1] Detect completed in 0.123s
│  ├─ [parse-session-123-1] Parsing started
│  ├─ [parse-session-123-1] 42 txns parsed in 0.456s
│  └─ [parse-session-123-1] Parse completed in 0.579s
├─ loadTargets()
│  ├─ [import-session-123] Queried 5 ledgers in 0.045s
│  └─ [import-session-123] Target auto-selected: ledger-456
├─ importTransactions()
│  ├─ [import-session-123] Import stage: matching
│  ├─ [import-session-123] 42 txns matched to ledger-456
│  ├─ [import-session-123] Import stage: inserting
│  ├─ [import-session-123] 40 txns inserted, 2 duplicates skipped
│  └─ [import-session-123] Import completed in 1.234s: success
└─ [import-session-123] Full import cycle completed: 3 files, 126 txns, 6 duplicates
```

### 4.2 Repository Operations

```
insertTransactions([...])
├─ [txn-insert-789] Insert 40 transactions to ledger-456
├─ [txn-insert-789] Constraint 1: ledgerId=456 sourceFingerprint=abc123
├─ [txn-insert-789] Inserted: 40, Skipped: 2 duplicates
└─ [txn-insert-789] Completed in 0.234s: success
```

### 4.3 Error Paths

```
parseFile(statement.pdf) throws
├─ [parse-session-123-1] Detect started
├─ [parse-session-123-1] ERROR: Unsupported bank format ICICI
├─ [parse-session-123-1] Technical: No parser registered for ICICI
├─ [parse-session-123-1] User message: "ICICI format not yet supported"
├─ [parse-session-123-1] Retryable: false
└─ [parse-session-123-1] Parse failed in 0.089s: ParsingError.unsupportedFormat
```

---

## Part 5: File Structure

### New Files to Create

```
Logging/
├── FinanceLogger.swift (expand)
├── OperationContext.swift (new)
├── PerformanceTimer.swift (new)
└── LogMetadata.swift (new)

Errors/
├── FinanceError.swift (new - protocol)
├── ParsingError.swift (new)
├── ImportError.swift (new)
├── DatabaseError.swift (new)
├── ValidationError.swift (new)
├── RepositoryError.swift (new)
├── FileAccessError.swift (new)
├── ErrorMapper.swift (new)
└── ErrorCategory.swift (new)

Utilities/
├── ErrorPresentation.swift (new)
└── ContextStack.swift (new)
```

### Modified Files

```
Database/
├── AppMigration.swift (add stage logging)
└── DatabaseManager.swift (enhance logging)

Repositories/
├── GRDBTransactionRepository.swift (add operation logging)
├── GRDBLedgerRepository.swift (add operation logging)
└── GRDBBankRepository.swift (add operation logging)

Importing/
├── TransactionImportPipeline.swift (add instrumentation)
├── ParsedTransactionMapper.swift (add logging)
├── ImportTargetMatcher.swift (add logging)
└── TransactionDeduplicator.swift (add logging)

Services/
├── FilenameMetadataExtractor.swift (fix silent failures)
└── AccountMatcher.swift (add logging)

Components/
├── EmptyStateView.swift (remove print)
└── SectionHeader.swift (remove print)
```

---

## Key Design Principles

1. **Zero Silent Failures**: Every error path logs before returning/throwing
2. **Correlation is Mandatory**: Import/parse context propagated through async boundaries
3. **Structured Over Strings**: Metadata as key-value pairs, not interpolated strings
4. **Privacy by Default**: Never log sensitive PII, document what's safe
5. **User vs. Technical**: Separate technical details (logged) from user messages (UI)
6. **Retryability Explicit**: Every error knows if it's retryable
7. **Severity Proportional**: Critical errors alert, warnings inform, info measures
8. **Duration Everything**: Timing data on all significant operations
9. **Category Routed**: Errors categorized for metrics, alerting, user guidance
10. **Context Preserved**: Every log includes enough detail to reproduce issue


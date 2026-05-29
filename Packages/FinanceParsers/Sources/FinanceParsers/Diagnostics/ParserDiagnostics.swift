import Foundation

/// Runtime telemetry collected during a single parse run: failed rows, timing,
/// duplicate count, and optional balance reconciliation. Stored in `ParseResult`
/// and surfaced in the import UI for user-visible warnings.
public struct ParserDiagnostics: Codable, Sendable, Equatable {
    /// Rows that could not be mapped to a `ParsedTransaction`, with failure reasons.
    public let failedRows: [FailedRow]
    /// Raw text lines that were skipped because they did not match any expected pattern.
    public let unmatchedLines: [String]
    /// Result of comparing computed vs stated opening/closing balances, if available.
    public let balanceValidation: BalanceValidationResult?
    /// Number of transactions that were dropped as duplicates during this parse run.
    public let duplicatesDetected: Int
    /// Non-fatal advisory messages about format quirks or data quality issues.
    public let warnings: [String]
    /// Wall-clock time taken for the parse run, in milliseconds.
    public let parserTimingMs: Double
    /// Total number of data rows attempted (excluding the header row).
    public let rowsProcessed: Int
    /// Number of rows that produced a valid `ParsedTransaction`.
    public let transactionsParsed: Int
    /// Rows intentionally skipped (e.g. blank lines, summary rows).
    public let skippedRows: Int

    public init(
        failedRows: [FailedRow] = [],
        unmatchedLines: [String] = [],
        balanceValidation: BalanceValidationResult? = nil,
        duplicatesDetected: Int = 0,
        warnings: [String] = [],
        parserTimingMs: Double = 0,
        rowsProcessed: Int = 0,
        transactionsParsed: Int = 0,
        skippedRows: Int = 0
    ) {
        self.failedRows = failedRows
        self.unmatchedLines = unmatchedLines
        self.balanceValidation = balanceValidation
        self.duplicatesDetected = duplicatesDetected
        self.warnings = warnings
        self.parserTimingMs = parserTimingMs
        self.rowsProcessed = rowsProcessed
        self.transactionsParsed = transactionsParsed
        self.skippedRows = skippedRows
    }
}

/// Captures a single row that could not be parsed, along with a human-readable failure reason.
public struct FailedRow: Codable, Sendable, Equatable {
    /// Zero-based row index in the original file.
    public let rowIndex: Int
    /// The raw field values of the failed row.
    public let rawContent: [String]
    /// Human-readable description of why the row was rejected.
    public let reason: String

    public init(
        rowIndex: Int,
        rawContent: [String],
        reason: String
    ) {
        self.rowIndex = rowIndex
        self.rawContent = rawContent
        self.reason = reason
    }
}

/// Compares the bank-stated opening/closing balances against the value computed
/// by summing all parsed transaction amounts, flagging any discrepancy.
public struct BalanceValidationResult: Codable, Sendable, Equatable {
    /// Opening balance from the statement header, in paise.
    public let openingBalance: Int64?
    /// Closing balance from the statement header, in paise.
    public let closingBalance: Int64?
    /// Closing balance derived by summing transactions from `openingBalance`, in paise.
    public let computedClosing: Int64?
    /// Difference between `closingBalance` and `computedClosing`; zero means reconciled.
    public let discrepancy: Int64?
    /// `true` when `closingBalance == computedClosing` (or neither is available).
    public let isValid: Bool

    public init(
        openingBalance: Int64?,
        closingBalance: Int64?,
        computedClosing: Int64?,
        discrepancy: Int64?,
        isValid: Bool
    ) {
        self.openingBalance = openingBalance
        self.closingBalance = closingBalance
        self.computedClosing = computedClosing
        self.discrepancy = discrepancy
        self.isValid = isValid
    }
}

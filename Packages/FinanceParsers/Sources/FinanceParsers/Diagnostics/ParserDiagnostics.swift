import Foundation

public struct ParserDiagnostics: Codable, Sendable {
    public let failedRows: [FailedRow]
    public let unmatchedLines: [String]
    public let balanceValidation: BalanceValidationResult?
    public let duplicatesDetected: Int
    public let warnings: [String]
    public let parserTimingMs: Double
    public let rowsProcessed: Int
    public let transactionsParsed: Int
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

public struct FailedRow: Codable, Sendable {
    public let rowIndex: Int
    public let rawContent: [String]
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

public struct BalanceValidationResult: Codable, Sendable {
    public let openingBalance: Int64?
    public let closingBalance: Int64?
    public let computedClosing: Int64?
    public let discrepancy: Int64?
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

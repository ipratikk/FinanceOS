//
//  HDFCStatementModels.swift
//  FinanceCore
//
//  Created by Pratik Goel on 15/05/26.
//

import Foundation

// Forward declaration to avoid circular dependency
// ParsedTransactionWithMetrics will be used with ParsedTransaction from ParsedTransaction.swift
// at the point of import

enum StatementLinePurpose {
    case header
    case footer
    case dateLine(dateString: String)
    case balanceLine(balanceString: String)
    case amountLine(amounts: [String])
    case narration
    case blank
    case unknown
}

struct ClassifiedLine {
    let rawText: String
    let purpose: StatementLinePurpose
    let confidence: Double
}

struct TransactionConfidence {
    let dateConfidence: Double
    let amountConfidence: Double
    let descriptionConfidence: Double

    var overallConfidence: Double {
        (dateConfidence + amountConfidence + descriptionConfidence) / 3.0
    }
}

struct ParseWarning {
    let category: String
    let message: String
    let lineNumber: Int
}

struct HDFCRawTransaction {
    let dateString: String
    let description: String
    let debitAmount: String?
    let creditAmount: String?
    let balance: String?
    let confidence: TransactionConfidence
    let warnings: [ParseWarning]
    let sourceLineIndices: [Int]
}

struct TransactionBlock {
    var lines: [ClassifiedLine]
    var dateLineIndex: Int?
    var amountLineIndices: [Int] = []
    var narrationLines: [ClassifiedLine] = []

    var isComplete: Bool {
        dateLineIndex != nil && !amountLineIndices.isEmpty
    }
}

struct BalanceDiscrepancy {
    let expectedBalance: Int64
    let calculatedBalance: Int64
    let transactionIndex: Int
    let difference: Int64
}

struct ValidationResult {
    let isValid: Bool
    let discrepancies: [BalanceDiscrepancy]
    let recoveryAttempted: Bool
    let recoveredTransactionCount: Int
}

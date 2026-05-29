import Foundation

/// Semantic classification of a single text line within an HDFC PDF statement.
enum StatementLinePurpose {
    case header
    case footer
    /// A line whose leading token matches the `dd/MM/yy` date pattern.
    case dateLine(dateString: String)
    /// A line carrying a running balance figure.
    case balanceLine(balanceString: String)
    /// A line containing one or more currency amounts (debit, credit, or balance).
    case amountLine(amounts: [String])
    case narration
    case blank
    case unknown
}

/// A text line paired with its inferred purpose and extraction confidence.
struct ClassifiedLine {
    let rawText: String
    let purpose: StatementLinePurpose
    /// 0.0–1.0 confidence that the classification is correct.
    let confidence: Double
}

/// Accumulates `ClassifiedLine` values that belong to a single transaction.
/// A block is considered complete once it has a date line and at least one amount line.
struct TransactionBlock {
    var lines: [ClassifiedLine]
    var dateLineIndex: Int?
    var amountLineIndices: [Int] = []
    var narrationLines: [ClassifiedLine] = []

    var isComplete: Bool {
        dateLineIndex != nil && !amountLineIndices.isEmpty
    }
}

/// Per-field confidence scores for a parsed HDFC transaction.
struct TransactionConfidence {
    let dateConfidence: Double
    let amountConfidence: Double
    let descriptionConfidence: Double

    /// Simple average of the three field confidences.
    var overallConfidence: Double {
        (dateConfidence + amountConfidence + descriptionConfidence) / 3.0
    }
}

/// Raw parsed transaction fields before normalisation, including extraction quality signals.
struct HDFCRawTransaction {
    let dateString: String
    let description: String
    let debitAmount: String?
    let creditAmount: String?
    let balance: String?
    let confidence: TransactionConfidence
    /// Non-fatal issues found during extraction (e.g. ambiguous amount column).
    let warnings: [String]
    let sourceLineIndices: [Int]
}

import Foundation

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

struct TransactionBlock {
    var lines: [ClassifiedLine]
    var dateLineIndex: Int?
    var amountLineIndices: [Int] = []
    var narrationLines: [ClassifiedLine] = []

    var isComplete: Bool {
        dateLineIndex != nil && !amountLineIndices.isEmpty
    }
}

struct TransactionConfidence {
    let dateConfidence: Double
    let amountConfidence: Double
    let descriptionConfidence: Double

    var overallConfidence: Double {
        (dateConfidence + amountConfidence + descriptionConfidence) / 3.0
    }
}

struct HDFCRawTransaction {
    let dateString: String
    let description: String
    let debitAmount: String?
    let creditAmount: String?
    let balance: String?
    let confidence: TransactionConfidence
    let warnings: [String]
    let sourceLineIndices: [Int]
}

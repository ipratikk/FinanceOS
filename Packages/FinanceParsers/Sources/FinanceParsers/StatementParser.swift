import Foundation

public enum StatementFileFormat: String, CaseIterable {
    case csv
    case txt
    case xlsx
    case pdf
}

public enum TransactionImportError: Error, CustomStringConvertible {
    case unsupportedFormat(String)
    case missingRequiredColumn(String)
    case invalidDate(String)
    case invalidAmount(String)
    case malformedFile(String)
    case platformUnavailable(String)
    case passwordProtected(String)

    public var description: String {
        switch self {
        case let .unsupportedFormat(format):
            return "Unsupported file format: \(format)"
        case let .missingRequiredColumn(column):
            return "Missing required column: \(column)"
        case let .invalidDate(value):
            return "Invalid date format: \(value)"
        case let .invalidAmount(value):
            return "Invalid amount: \(value)"
        case let .malformedFile(description):
            return "File is malformed: \(description)"
        case let .platformUnavailable(description):
            return description
        case let .passwordProtected(filename):
            return "Password required for: \(filename)"
        }
    }
}

public struct ParsedTransaction: Codable, Identifiable {
    public let id: UUID
    public let postedAt: Date
    public let description: String
    public let amountMinorUnits: Int64
    public let currencyCode: String
    public let sourceFingerprint: String
    public let rewardPoints: Int64?

    public init(
        postedAt: Date,
        description: String,
        amountMinorUnits: Int64,
        currencyCode: String,
        sourceFingerprint: String,
        rewardPoints: Int64? = nil
    ) {
        id = UUID()
        self.postedAt = postedAt
        self.description = description
        self.amountMinorUnits = amountMinorUnits
        self.currencyCode = currencyCode
        self.sourceFingerprint = sourceFingerprint
        self.rewardPoints = rewardPoints
    }

    enum CodingKeys: String, CodingKey {
        case id, postedAt, description, amountMinorUnits, currencyCode, sourceFingerprint, rewardPoints
    }
}

public struct ParsedStatement: Codable {
    public let bankName: String
    public let accountName: String
    public let statementPeriodStart: Date
    public let statementPeriodEnd: Date
    public let currency: String
    public let totalDebit: Int64
    public let totalCredit: Int64
    public let transactions: [ParsedTransaction]

    public init(
        bankName: String,
        accountName: String,
        statementPeriodStart: Date,
        statementPeriodEnd: Date,
        currency: String,
        totalDebit: Int64,
        totalCredit: Int64,
        transactions: [ParsedTransaction]
    ) {
        self.bankName = bankName
        self.accountName = accountName
        self.statementPeriodStart = statementPeriodStart
        self.statementPeriodEnd = statementPeriodEnd
        self.currency = currency
        self.totalDebit = totalDebit
        self.totalCredit = totalCredit
        self.transactions = transactions
    }
}

public protocol StatementParser {
    var supportedFormat: StatementFileFormat { get }
    func parseStatement(from fileURL: URL) async throws -> ParsedStatement
}

public struct StatementParserRegistry {
    private let parsers: [StatementParser]

    public init(parsers: [StatementParser]) {
        self.parsers = parsers
    }

    public var supportedSources: [(bankName: String, sourceType: String)] {
        [
            ("HDFC", "Bank Account"),
            ("HDFC", "Credit Card"),
            ("ICICI", "Bank Account"),
            ("ICICI", "Credit Card"),
            ("Amex", "Credit Card")
        ]
    }

    public func parser(for format: StatementFileFormat) -> StatementParser? {
        parsers.first { $0.supportedFormat == format }
    }
}

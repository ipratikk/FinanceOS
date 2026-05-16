import Foundation

public enum StatementFileFormat: String, CaseIterable, Sendable {
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

    public var userMessage: String {
        description
    }
}

public struct ParsedTransaction: Codable, Identifiable, Sendable {
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

public struct StatementMetadata: Codable, Sendable {
    public let customerName: String?
    public let customerId: String?
    public let accountNumber: String?
    public let accountType: String?
    public let branch: String?
    public let branchCode: String?
    public let address: String?
    public let email: String?
    public let phone: String?
    public let ifsc: String?
    public let micr: String?
    public let openingBalance: Int64?
    public let closingBalance: Int64?
    public let debitCount: Int?
    public let creditCount: Int?
    public let generatedAt: Date?

    public init(
        customerName: String? = nil,
        customerId: String? = nil,
        accountNumber: String? = nil,
        accountType: String? = nil,
        branch: String? = nil,
        branchCode: String? = nil,
        address: String? = nil,
        email: String? = nil,
        phone: String? = nil,
        ifsc: String? = nil,
        micr: String? = nil,
        openingBalance: Int64? = nil,
        closingBalance: Int64? = nil,
        debitCount: Int? = nil,
        creditCount: Int? = nil,
        generatedAt: Date? = nil
    ) {
        self.customerName = customerName
        self.customerId = customerId
        self.accountNumber = accountNumber
        self.accountType = accountType
        self.branch = branch
        self.branchCode = branchCode
        self.address = address
        self.email = email
        self.phone = phone
        self.ifsc = ifsc
        self.micr = micr
        self.openingBalance = openingBalance
        self.closingBalance = closingBalance
        self.debitCount = debitCount
        self.creditCount = creditCount
        self.generatedAt = generatedAt
    }
}

public struct ParsedStatement: Codable, Sendable {
    public let bankName: String
    public let accountName: String
    public let accountLast4: String?
    public let cardLast4: String?
    public let statementPeriodStart: Date?
    public let statementPeriodEnd: Date?
    public let currency: String
    public let totalDebit: Int64
    public let totalCredit: Int64
    public let transactions: [ParsedTransaction]
    public let metadata: StatementMetadata?

    public init(
        bankName: String,
        accountName: String,
        accountLast4: String? = nil,
        cardLast4: String? = nil,
        statementPeriodStart: Date? = nil,
        statementPeriodEnd: Date? = nil,
        currency: String = "INR",
        totalDebit: Int64 = 0,
        totalCredit: Int64 = 0,
        transactions: [ParsedTransaction] = [],
        metadata: StatementMetadata? = nil
    ) {
        self.bankName = bankName
        self.accountName = accountName
        self.accountLast4 = accountLast4
        self.cardLast4 = cardLast4
        self.statementPeriodStart = statementPeriodStart
        self.statementPeriodEnd = statementPeriodEnd
        self.currency = currency
        self.totalDebit = totalDebit
        self.totalCredit = totalCredit
        self.transactions = transactions
        self.metadata = metadata
    }
}

public protocol StatementParser: Sendable {
    var supportedFormat: StatementFileFormat { get }
    func parseStatement(from fileURL: URL) async throws -> ParsedStatement
}

public struct DefaultTransactionImporter: Sendable {
    private let parsersByFormat: [StatementFileFormat: any StatementParser]

    public init(
        parsers: [any StatementParser]? = nil
    ) {
        var parsersByFormat: [StatementFileFormat: any StatementParser] = [:]

        let defaultParsers: [any StatementParser] = parsers ?? [
            CSVStatementParser(),
            XLSXStatementParser(),
            TXTStatementParser(),
            HDFCPDFParser()
        ]

        for parser in defaultParsers {
            parsersByFormat[parser.supportedFormat] = parser
        }

        self.parsersByFormat = parsersByFormat
    }

    public func parseStatement(
        from fileURL: URL,
        format: StatementFileFormat
    ) async throws -> ParsedStatement {
        guard let formatParser = parsersByFormat[format] else {
            throw TransactionImportError.unsupportedFormat(format.rawValue)
        }

        return try await formatParser.parseStatement(from: fileURL)
    }
}

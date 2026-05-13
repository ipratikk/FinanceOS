import Foundation

public struct ParsedStatement: Sendable {
    public let institution: String
    public let accountName: String
    public let cardLast4: String?
    public let statementPeriodStart: Date?
    public let statementPeriodEnd: Date?
    public let currency: String
    public let totalDebit: Int64
    public let totalCredit: Int64
    public let transactions: [ParsedTransaction]

    public init(
        institution: String,
        accountName: String,
        cardLast4: String? = nil,
        statementPeriodStart: Date? = nil,
        statementPeriodEnd: Date? = nil,
        currency: String = "INR",
        totalDebit: Int64 = 0,
        totalCredit: Int64 = 0,
        transactions: [ParsedTransaction] = []
    ) {
        self.institution = institution
        self.accountName = accountName
        self.cardLast4 = cardLast4
        self.statementPeriodStart = statementPeriodStart
        self.statementPeriodEnd = statementPeriodEnd
        self.currency = currency
        self.totalDebit = totalDebit
        self.totalCredit = totalCredit
        self.transactions = transactions
    }
}

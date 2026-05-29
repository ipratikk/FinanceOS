import Foundation

/// The fully-parsed output of one bank statement: header metadata plus all transactions.
/// Amounts are in minor units (paise). Produced by the Mapper/Normalizer stage and consumed
/// by the import pipeline for deduplication and persistence.
public struct ParsedStatement: Codable, Sendable, Equatable {
    /// Short institution name, e.g. `"HDFC"`.
    public let bankName: String
    /// Customer or account display name extracted from statement metadata.
    public let accountName: String
    /// Last 4 digits of the bank account number, if available.
    public let accountLast4: String?
    /// Last 4 digits of the credit card number, if available.
    public let cardLast4: String?
    /// First transaction date in the statement period, if detectable.
    public let statementPeriodStart: Date?
    /// Last transaction date in the statement period, if detectable.
    public let statementPeriodEnd: Date?
    /// ISO 4217 currency code, typically `"INR"`.
    public let currency: String
    /// Sum of all debit amounts in minor units (positive values).
    public let totalDebit: Int64
    /// Sum of all credit amounts in minor units (absolute values).
    public let totalCredit: Int64
    /// Ordered list of transactions as parsed from the raw file.
    public let transactions: [ParsedTransaction]
    /// Additional structured metadata extracted from the statement header.
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

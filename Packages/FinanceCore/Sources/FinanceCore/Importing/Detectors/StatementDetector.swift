public protocol StatementDetector: Sendable {
    func detect(from rows: [[String]]) -> DetectedStatementMetadata?
}

public struct DetectedStatementMetadata: Sendable {
    public let institution: String
    public let accountName: String
    public let cardLast4: String?
    public let transactionStartIndex: Int

    public init(
        institution: String,
        accountName: String,
        cardLast4: String? = nil,
        transactionStartIndex: Int
    ) {
        self.institution = institution
        self.accountName = accountName
        self.cardLast4 = cardLast4
        self.transactionStartIndex = transactionStartIndex
    }
}

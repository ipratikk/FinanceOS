public struct AmexCardStatementParser: InstitutionStatementParser {
    public let institution = "Amex"
    public let sourceType = StatementSourceType.creditCard

    public init() {}

    public func canParse(rows: [[String]]) -> Bool {
        // Awaiting sample files from user
        return false
    }

    public func parse(rows: [[String]]) throws -> ParsedStatement {
        throw TransactionImportError.unsupportedFormat(.csv)
    }
}

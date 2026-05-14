public struct HDFCBankStatementParser: InstitutionStatementParser {
    public let institution = "HDFC"
    public let sourceType = StatementSourceType.bankAccount

    public init() {}

    public func canParse(rows: [[String]]) -> Bool {
        // Awaiting sample files from user
        return false
    }

    public func parse(rows: [[String]]) throws -> ParsedStatement {
        throw TransactionImportError.unsupportedFormat(.csv)
    }
}

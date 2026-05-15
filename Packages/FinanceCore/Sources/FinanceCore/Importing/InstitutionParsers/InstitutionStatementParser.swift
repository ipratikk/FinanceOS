public protocol InstitutionStatementParser: Sendable {
    var bankName: String { get }
    var sourceType: StatementSourceType { get }

    func canParse(rows: [[String]]) -> Bool
    func parse(rows: [[String]]) throws -> ParsedStatement
}

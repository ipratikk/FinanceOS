public protocol InstitutionStatementParser: Sendable {
    var institution: String { get }
    var sourceType: StatementSourceType { get }

    func canParse(rows: [[String]]) -> Bool
    func parse(rows: [[String]]) throws -> ParsedStatement
}

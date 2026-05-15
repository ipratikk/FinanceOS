public struct StatementParserRegistry: Sendable {
    public let parsers: [any InstitutionStatementParser]

    public init(parsers: [any InstitutionStatementParser]) {
        self.parsers = parsers
    }

    public var supportedSources: [(bankName: String, sourceType: StatementSourceType)] {
        parsers.map { ($0.bankName, $0.sourceType) }
    }

    func parser(for rows: [[String]]) -> (any InstitutionStatementParser)? {
        parsers.first { $0.canParse(rows: rows) }
    }
}

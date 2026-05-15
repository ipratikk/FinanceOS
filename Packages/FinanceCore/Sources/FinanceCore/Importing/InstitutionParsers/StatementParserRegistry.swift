public struct StatementParserRegistry: Sendable {
    public let parsers: [any InstitutionStatementParser]

    public init(parsers: [any InstitutionStatementParser]) {
        self.parsers = parsers
    }

    public var supportedSources: [(bankName: String, sourceType: StatementSourceType)] {
        parsers.map { ($0.bankName, $0.sourceType) }
    }

    public func parser(for source: StatementSource) -> (any InstitutionStatementParser)? {
        parsers.first { $0.bankName == source.bankName && $0.sourceType == source.sourceType }
    }

    func parser(for rows: [[String]]) -> (any InstitutionStatementParser)? {
        parsers.first { $0.canParse(rows: rows) }
    }
}

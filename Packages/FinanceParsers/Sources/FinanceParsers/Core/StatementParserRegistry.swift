/// Immutable collection of `InstitutionStatementParser` instances, used to look up
/// the correct parser either by explicit `StatementSource` or by probing raw rows.
public struct StatementParserRegistry: Sendable {
    /// All registered parsers, in priority order for auto-detection.
    public let parsers: [any InstitutionStatementParser]

    public init(parsers: [any InstitutionStatementParser]) {
        self.parsers = parsers
    }

    /// Bank-name / source-type pairs for every registered parser.
    public var supportedSources: [(bankName: String, sourceType: StatementSourceType)] {
        parsers.map { ($0.bankName, $0.sourceType) }
    }

    /// Returns the parser whose `bankName` and `sourceType` match `source`, or `nil` if none registered.
    public func parser(for source: StatementSource) -> (any InstitutionStatementParser)? {
        parsers.first { $0.bankName == source.bankName && $0.sourceType == source.sourceType }
    }

    /// Returns the first parser that reports `canParse(rows:) == true`, or `nil` if unrecognized.
    func parser(for rows: [[String]]) -> (any InstitutionStatementParser)? {
        parsers.first { $0.canParse(rows: rows) }
    }
}

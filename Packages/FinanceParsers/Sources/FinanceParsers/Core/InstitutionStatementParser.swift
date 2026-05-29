/// Entry point for a single bank-format combination in the parse pipeline.
/// Implementors own the full path from raw CSV rows to a `ParsedStatement`
/// and must be stateless and `Sendable`.
public protocol InstitutionStatementParser: Sendable {
    /// Human-readable institution identifier, e.g. `"HDFC"`.
    var bankName: String { get }

    /// Format revision string used in `ParseResult.institutionVersion`, e.g. `"HDFC-Card-1.0"`.
    var institutionVersion: String { get }

    /// Whether this parser targets a bank account or credit card statement.
    var sourceType: StatementSourceType { get }

    /// Returns `true` when `rows` match the header/structural signature of this parser's format.
    func canParse(rows: [[String]]) -> Bool

    /// Converts raw rows (header + data) into a `ParsedStatement`. Throws on malformed input.
    func parse(rows: [[String]]) throws -> ParsedStatement
}

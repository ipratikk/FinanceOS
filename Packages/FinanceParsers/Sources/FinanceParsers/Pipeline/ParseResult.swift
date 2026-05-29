import Foundation

/// The complete output of a successful parse run: the parsed statement, diagnostics,
/// version provenance, and a confidence score. Conforms to `Codable` for golden-fixture storage.
public struct ParseResult: Codable, Sendable, Equatable {
    /// Version of the JSON schema used to encode this result (currently `"1.0"`).
    public let schemaVersion: String
    /// Version of the `UnifiedStatementParser` build that produced this result.
    public let parserVersion: String
    /// Institution-specific format version, e.g. `"HDFC-Card-1.0"`.
    public let institutionVersion: String
    /// The fully parsed statement including all transactions.
    public let statement: ParsedStatement
    /// Timing, failure, and validation diagnostics from the parse run.
    public let diagnostics: ParserDiagnostics
    /// Parser's self-reported confidence that the file was correctly identified; 0–1.
    public let confidence: Double

    public init(
        schemaVersion: String = "1.0",
        parserVersion: String = "dev",
        institutionVersion: String,
        statement: ParsedStatement,
        diagnostics: ParserDiagnostics,
        confidence: Double = 1.0
    ) {
        self.schemaVersion = schemaVersion
        self.parserVersion = parserVersion
        self.institutionVersion = institutionVersion
        self.statement = statement
        self.diagnostics = diagnostics
        self.confidence = confidence
    }
}

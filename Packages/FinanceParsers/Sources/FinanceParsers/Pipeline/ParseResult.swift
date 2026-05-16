import Foundation

public struct ParseResult: Codable, Sendable, Equatable {
    public let schemaVersion: String
    public let parserVersion: String
    public let institutionVersion: String
    public let statement: ParsedStatement
    public let diagnostics: ParserDiagnostics
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

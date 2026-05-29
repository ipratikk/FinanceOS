import Foundation

/// Supported file formats that the import pipeline accepts.
public enum StatementFileFormat: String, CaseIterable, Sendable {
    case csv
    case txt
    case xlsx
    case pdf
}

/// Errors thrown during statement import and parsing.
public enum TransactionImportError: Error, CustomStringConvertible {
    /// The file extension or format identifier is not handled by any registered parser.
    case unsupportedFormat(String)
    /// A required CSV column header was absent from the file.
    case missingRequiredColumn(String)
    /// A date string could not be parsed with any of the institution's expected formats.
    case invalidDate(String)
    /// An amount string could not be converted to a numeric value.
    case invalidAmount(String)
    /// The file structure is inconsistent or corrupt in a way that prevents parsing.
    case malformedFile(String)
    /// A required platform capability (e.g. CoreXLSX on non-Darwin) is unavailable.
    case platformUnavailable(String)
    /// The file is encrypted and a password must be supplied via `ParseOptions`.
    case passwordProtected(String)

    public var description: String {
        switch self {
        case let .unsupportedFormat(format):
            return "Unsupported file format: \(format)"
        case let .missingRequiredColumn(column):
            return "Missing required column: \(column)"
        case let .invalidDate(value):
            return "Invalid date format: \(value)"
        case let .invalidAmount(value):
            return "Invalid amount: \(value)"
        case let .malformedFile(description):
            return "File is malformed: \(description)"
        case let .platformUnavailable(description):
            return description
        case let .passwordProtected(filename):
            return "Password required for: \(filename)"
        }
    }

    /// Alias for `description`; suitable for display in the import UI.
    public var userMessage: String {
        description
    }
}

/// Protocol for format-level parsers that handle a single `StatementFileFormat`.
/// Implementors are responsible only for reading the raw file; they produce a `ParsedStatement`
/// which is then handed to the deduplication and persistence pipeline.
public protocol StatementParser: Sendable {
    /// The file format this parser handles.
    var supportedFormat: StatementFileFormat { get }

    /// Reads `fileURL` and returns a fully populated `ParsedStatement`.
    func parseStatement(from fileURL: URL) async throws -> ParsedStatement
}

/// Routes a parse request to the correct `StatementParser` based on `StatementFileFormat`.
/// Intended for format-dispatch scenarios where institution detection is handled upstream.
public struct DefaultTransactionImporter: Sendable {
    private let parsersByFormat: [StatementFileFormat: any StatementParser]

    public init(
        parsers: [any StatementParser]? = nil
    ) {
        var parsersByFormat: [StatementFileFormat: any StatementParser] = [:]

        let defaultParsers: [any StatementParser] = parsers ?? [
            HDFCPDFParser()
        ]

        for parser in defaultParsers {
            parsersByFormat[parser.supportedFormat] = parser
        }

        self.parsersByFormat = parsersByFormat
    }

    /// Dispatches parsing to the registered parser for `format`.
    /// Throws `TransactionImportError.unsupportedFormat` when no parser is registered.
    public func parseStatement(
        from fileURL: URL,
        format: StatementFileFormat
    ) async throws -> ParsedStatement {
        guard let formatParser = parsersByFormat[format] else {
            throw TransactionImportError.unsupportedFormat(format.rawValue)
        }

        return try await formatParser.parseStatement(from: fileURL)
    }
}

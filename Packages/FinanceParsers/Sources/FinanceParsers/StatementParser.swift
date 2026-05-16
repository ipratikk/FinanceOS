import Foundation

public enum StatementFileFormat: String, CaseIterable, Sendable {
    case csv
    case txt
    case xlsx
    case pdf
}

public enum TransactionImportError: Error, CustomStringConvertible {
    case unsupportedFormat(String)
    case missingRequiredColumn(String)
    case invalidDate(String)
    case invalidAmount(String)
    case malformedFile(String)
    case platformUnavailable(String)
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

    public var userMessage: String {
        description
    }
}

public protocol StatementParser: Sendable {
    var supportedFormat: StatementFileFormat { get }
    func parseStatement(from fileURL: URL) async throws -> ParsedStatement
}

public struct DefaultTransactionImporter: Sendable {
    private let parsersByFormat: [StatementFileFormat: any StatementParser]

    public init(
        parsers: [any StatementParser]? = nil
    ) {
        var parsersByFormat: [StatementFileFormat: any StatementParser] = [:]

        let defaultParsers: [any StatementParser] = parsers ?? [
            CSVStatementParser(),
            XLSXStatementParser(),
            TXTStatementParser(),
            HDFCPDFParser()
        ]

        for parser in defaultParsers {
            parsersByFormat[parser.supportedFormat] = parser
        }

        self.parsersByFormat = parsersByFormat
    }

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

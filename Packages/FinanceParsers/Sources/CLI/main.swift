import ArgumentParser
import FinanceParsers
import Foundation

@main
struct FinanceParserCLI: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "finance-parser",
        abstract: "Financial statement ingestion and parsing engine",
        version: "0.1.0",
        subcommands: [
            ParseCommand.self,
            ValidateCommand.self,
            ListSourcesCommand.self,
            CompareCommand.self
        ],
        defaultSubcommand: ParseCommand.self
    )
}

// MARK: - Parse Command

struct ParseCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "parse",
        abstract: "Parse a statement file and output normalized JSON"
    )

    @Argument(help: "Path to statement file")
    var filePath: String

    @Option(help: "Statement source (e.g., hdfcBank, iciciCard, amex)")
    var source: String?

    @Option(help: "Password for encrypted PDFs")
    var password: String?

    @Flag(help: "Include diagnostic information in output")
    var diagnostics = false

    @Flag(help: "Verbose output with timing and intermediate stages")
    var verbose = false

    @Flag(help: "Output compact JSON (default is pretty-printed)")
    var compact = false

    func run() async throws {
        let fileURL = URL(fileURLWithPath: filePath)

        guard FileManager.default.fileExists(atPath: filePath) else {
            throw CLIError.fileNotFound(filePath)
        }

        let fileExtension = fileURL.pathExtension.lowercased()
        guard let format = StatementFileFormat(rawValue: fileExtension) else {
            throw CLIError.unsupportedFormat(fileExtension)
        }

        do {
            let startTime = Date()
            let statement = try await parseStatement(fileURL: fileURL, format: format)
            let duration = Date().timeIntervalSince(startTime)

            let output = compact ? encodeCompact(statement) : encodePretty(statement)
            print(output)

            if verbose {
                fputs("Parse completed in \(String(format: "%.2f", duration))ms\n", stderr)
            }
        } catch let error as TransactionImportError {
            throw CLIError.parseError(error.description)
        } catch {
            throw CLIError.parseError(error.localizedDescription)
        }
    }

    private func parseStatement(fileURL: URL, format: StatementFileFormat) async throws -> ParsedStatement {
        let parser: StatementParser = {
            switch format {
            case .pdf:
                return HDFCPDFParser(password: password)
            case .csv:
                return CSVStatementParser()
            case .txt:
                return TXTStatementParser()
            case .xlsx:
                return XLSXStatementParser()
            }
        }()

        return try await parser.parseStatement(from: fileURL)
    }

    private func encodePretty(_ statement: ParsedStatement) -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        if #available(macOS 10.13, *) {
            encoder.dateEncodingStrategy = .iso8601
        }
        guard let data = try? encoder.encode(statement),
              let json = String(data: data, encoding: .utf8) else {
            return "{}"
        }
        return json
    }

    private func encodeCompact(_ statement: ParsedStatement) -> String {
        let encoder = JSONEncoder()
        if #available(macOS 10.13, *) {
            encoder.dateEncodingStrategy = .iso8601
        }
        guard let data = try? encoder.encode(statement),
              let json = String(data: data, encoding: .utf8) else {
            return "{}"
        }
        return json
    }
}

// MARK: - Validate Command

struct ValidateCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "validate",
        abstract: "Validate a statement file and report issues"
    )

    @Argument(help: "Path to statement file")
    var filePath: String

    @Option(help: "Password for encrypted PDFs")
    var password: String?

    func run() async throws {
        let fileURL = URL(fileURLWithPath: filePath)

        guard FileManager.default.fileExists(atPath: filePath) else {
            throw CLIError.fileNotFound(filePath)
        }

        let fileExtension = fileURL.pathExtension.lowercased()
        guard let format = StatementFileFormat(rawValue: fileExtension) else {
            throw CLIError.unsupportedFormat(fileExtension)
        }

        do {
            let statement = try await parseStatement(fileURL: fileURL, format: format)

            print("✓ Valid statement parsed")
            print("  Bank: \(statement.bankName)")
            print("  Account: \(statement.accountName)")
            if let cardLast4 = statement.cardLast4 {
                print("  Card: ****\(cardLast4)")
            }
            print("  Transactions: \(statement.transactions.count)")
            print("  Period: \(formatDate(statement.statementPeriodStart)) to \(formatDate(statement.statementPeriodEnd))")
            print("  Currency: \(statement.currency)")
            print("  Total Debit: \(formatAmount(statement.totalDebit))")
            print("  Total Credit: \(formatAmount(statement.totalCredit))")
        } catch let error as TransactionImportError {
            throw CLIError.parseError(error.description)
        } catch {
            throw CLIError.parseError(error.localizedDescription)
        }
    }

    private func parseStatement(fileURL: URL, format: StatementFileFormat) async throws -> ParsedStatement {
        let parser: StatementParser = {
            switch format {
            case .pdf:
                return HDFCPDFParser(password: password)
            case .csv:
                return CSVStatementParser()
            case .txt:
                return TXTStatementParser()
            case .xlsx:
                return XLSXStatementParser()
            }
        }()

        return try await parser.parseStatement(from: fileURL)
    }

    private func formatDate(_ date: Date?) -> String {
        guard let date = date else { return "unknown" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    private func formatAmount(_ minorUnits: Int64) -> String {
        let amount = Double(minorUnits) / 100.0
        return String(format: "%.2f", amount)
    }
}

// MARK: - List Sources Command

struct ListSourcesCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list-sources",
        abstract: "List all registered institution parsers"
    )

    func run() throws {
        let registry = StatementParserRegistry(
            parsers: [
                ICICIBankStatementParser(),
                ICICICardStatementParser(),
                HDFCBankStatementParser(),
                HDFCCardStatementParser(),
                AmexCardStatementParser()
            ]
        )

        let sources = registry.supportedSources
        print("Registered statement sources:")
        for (bankName, sourceType) in sources {
            print("  • \(bankName) - \(sourceType.rawValue)")
        }
    }
}

// MARK: - Compare Command

struct CompareCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "compare",
        abstract: "Compare parsed output with expected JSON"
    )

    @Argument(help: "Path to statement file")
    var filePath: String

    @Option(help: "Path to expected JSON output")
    var expected: String?

    @Option(help: "Password for encrypted PDFs")
    var password: String?

    func run() async throws {
        let fileURL = URL(fileURLWithPath: filePath)

        guard FileManager.default.fileExists(atPath: filePath) else {
            throw CLIError.fileNotFound(filePath)
        }

        let fileExtension = fileURL.pathExtension.lowercased()
        guard let format = StatementFileFormat(rawValue: fileExtension) else {
            throw CLIError.unsupportedFormat(fileExtension)
        }

        do {
            let statement = try await parseStatement(fileURL: fileURL, format: format)
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

            guard let actualData = try? encoder.encode(statement),
                  let actualJSON = String(data: actualData, encoding: .utf8) else {
                throw CLIError.parseError("Failed to encode statement as JSON")
            }

            if let expectedPath = expected {
                let expectedJSON = try String(contentsOfFile: expectedPath, encoding: .utf8)

                if actualJSON == expectedJSON {
                    print("✓ Output matches expected JSON")
                } else {
                    print("✗ Output differs from expected JSON")
                    print("\nActual:")
                    print(actualJSON)
                    print("\nExpected:")
                    print(expectedJSON)
                }
            } else {
                print(actualJSON)
            }
        } catch let error as TransactionImportError {
            throw CLIError.parseError(error.description)
        } catch {
            throw CLIError.parseError(error.localizedDescription)
        }
    }

    private func parseStatement(fileURL: URL, format: StatementFileFormat) async throws -> ParsedStatement {
        let parser: StatementParser = {
            switch format {
            case .pdf:
                return HDFCPDFParser(password: password)
            case .csv:
                return CSVStatementParser()
            case .txt:
                return TXTStatementParser()
            case .xlsx:
                return XLSXStatementParser()
            }
        }()

        return try await parser.parseStatement(from: fileURL)
    }
}

// MARK: - Error Handling

enum CLIError: Error, CustomStringConvertible {
    case fileNotFound(String)
    case unsupportedFormat(String)
    case parseError(String)

    var description: String {
        switch self {
        case let .fileNotFound(path):
            return "Error: File not found at \(path)"
        case let .unsupportedFormat(format):
            return "Error: Unsupported file format: \(format)"
        case let .parseError(message):
            return "Error: \(message)"
        }
    }
}

extension CLIError: LocalizedError {
    var errorDescription: String? {
        description
    }
}

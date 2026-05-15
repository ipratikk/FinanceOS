import ArgumentParser
import FinanceParsers
import Foundation

@main
struct FinanceParserCLI: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "FinanceParserCLI",
        subcommands: [ParseCommand.self],
        defaultSubcommand: ParseCommand.self
    )
}

struct ParseCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "parse",
        abstract: "Parse a bank statement file and output normalized JSON"
    )

    @Argument(help: "Path to statement file (PDF, CSV, XLSX, or TXT)")
    var filePath: String

    @Option(help: "Password for encrypted PDFs")
    var password: String?

    @Flag(help: "Output raw debug information")
    var debug = false

    func run() async throws {
        let fileURL = URL(fileURLWithPath: filePath)

        guard FileManager.default.fileExists(atPath: filePath) else {
            print("Error: File not found at \(filePath)")
            throw ExitCode.failure
        }

        let fileExtension = fileURL.pathExtension.lowercased()
        guard let format = StatementFileFormat(rawValue: fileExtension) else {
            print("Error: Unsupported file format: \(fileExtension)")
            throw ExitCode.failure
        }

        let parser: StatementParser = {
            switch format {
            case .pdf:
                return HDFCPDFParser(password: password)
            default:
                fatalError("Format not yet supported: \(format)")
            }
        }()

        do {
            let statement = try await parser.parseStatement(from: fileURL)

            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let jsonData = try encoder.encode(statement)

            if let jsonString = String(data: jsonData, encoding: .utf8) {
                print(jsonString)
            }
        } catch let error as TransactionImportError {
            print("Error: \(error.description)")
            throw ExitCode.failure
        } catch {
            print("Error: \(error.localizedDescription)")
            throw ExitCode.failure
        }
    }
}

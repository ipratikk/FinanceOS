import FinanceCore
import FinanceParsers
import Foundation
import Observation
import OSLog

let logger = FinanceLogger.importPipeline

func fuzzyMatch(_ stored: String, _ parsed: String) -> Bool {
    let storedLower = stored.lowercased()
    let parsedLower = parsed.lowercased()

    if storedLower == parsedLower { return true }
    if storedLower.contains(parsedLower) || parsedLower.contains(storedLower) { return true }

    let storedWords = storedLower.split(separator: " ").map(String.init)
    let parsedWords = parsedLower.split(separator: " ").map(String.init)

    let commonWords = Set(storedWords).intersection(Set(parsedWords))
    return !commonWords.isEmpty && commonWords.count >= min(storedWords.count, parsedWords.count) / 2
}

private func transactionHash(_ txn: ParsedTransaction) -> String {
    let dateStr = ISO8601DateFormatter().string(from: Calendar.current.startOfDay(for: txn.postedAt))
    let amountStr = String(txn.amountMinorUnits)
    let descStr = txn.description.trimmingCharacters(in: .whitespaces).lowercased()
    let combined = "\(dateStr)|\(amountStr)|\(descStr)"
    return String(combined.hashValue)
}

private func transactionHash(_ txn: Transaction) -> String {
    let dateStr = ISO8601DateFormatter().string(from: Calendar.current.startOfDay(for: txn.postedAt))
    let amountStr = String(txn.amountMinorUnits)
    let descStr = txn.description.trimmingCharacters(in: .whitespaces).lowercased()
    let combined = "\(dateStr)|\(amountStr)|\(descStr)"
    return String(combined.hashValue)
}

func isSameTransaction(parsed: ParsedTransaction, existing: Transaction) -> Bool {
    transactionHash(parsed) == transactionHash(existing)
}

func fileFormat(for url: URL) -> StatementFileFormat {
    let pathExtension = url.pathExtension.lowercased()
    logger.debug("File extension: '\(pathExtension, privacy: .public)'")

    switch pathExtension {
    case "csv":
        return .csv
    case "txt":
        return .txt
    case "xlsx":
        return .xlsx
    case "pdf":
        return .pdf
    default:
        logger.warning("Unknown extension '\(pathExtension, privacy: .public)', defaulting to CSV")
        return .csv
    }
}

private func formatError(_ error: FinanceCore.TransactionImportError) -> String {
    switch error {
    case let .unsupportedFormat(format):
        return "Unsupported file format: \(format.rawValue)"
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

@MainActor
@Observable
final class ImportViewModel {
    var fileURLs: [URL] = []
    var parsedStatements: [ParsedStatement] = []
    var selectedTarget: TransactionImportTarget?
    var selectedSource: StatementSource?

    var isLoading = false
    var errorMessage: String?
    var importResult: ImportResult?
    var passwordPromptFilename: String?
    var isPasswordInvalid = false

    var accounts: [Account] = []
    var cards: [Card] = []
    var banks: [Bank] = []
    var duplicateTransactionIndices: Set<Int> = []

    var pdfPassword: String?

    var fileStatementPairs: [(url: URL, statement: ParsedStatement)] {
        zip(fileURLs, parsedStatements).map { ($0, $1) }
    }

    var supportedSources: [(bankName: String, sourceType: StatementSourceType)] {
        parserRegistry.supportedSources
    }

    let transactionImporter: any TransactionImporting
    let transactionImportPipeline: TransactionImportPipeline
    let bankRepository: any BankRepository
    let accountRepository: any AccountRepository
    let cardRepository: any CardRepository
    let transactionRepository: any TransactionRepository
    let parserRegistry: FinanceCore.StatementParserRegistry

    init(
        transactionImporter: any TransactionImporting,
        transactionImportPipeline: TransactionImportPipeline,
        bankRepository: any BankRepository,
        accountRepository: any AccountRepository,
        cardRepository: any CardRepository,
        transactionRepository: any TransactionRepository,
        parserRegistry: FinanceCore.StatementParserRegistry
    ) {
        self.transactionImporter = transactionImporter
        self.transactionImportPipeline = transactionImportPipeline
        self.bankRepository = bankRepository
        self.accountRepository = accountRepository
        self.cardRepository = cardRepository
        self.transactionRepository = transactionRepository
        self.parserRegistry = parserRegistry
    }

    func setFileURLs(_ urls: [URL]) {
        logger.info("setFileURLs called with \(urls.count, privacy: .public) file(s)")
        fileURLs = urls
        errorMessage = nil
        logger.debug("fileURLs updated, errorMessage cleared")
    }

    func setSource(_ source: StatementSource?) {
        selectedSource = source
        fileURLs = []
        parsedStatements = []
        errorMessage = nil
        logger
            .info("Source changed to \(source?.displayName ?? "none", privacy: .public), cleared files and statements")
    }

    func parseFiles() {
        logger.info("parseFiles() called, scheduling Task")
        Task {
            guard !fileURLs.isEmpty else {
                errorMessage = "No files selected"
                return
            }

            isLoading = true
            errorMessage = nil
            var statements: [ParsedStatement] = []

            for fileURL in fileURLs {
                let result = await parseFile(fileURL, withPassword: nil)
                if let statement = result.0 {
                    statements.append(statement)
                } else if result.1 {
                    return
                }
            }

            self.parsedStatements = statements
            await loadTargetsOnAppear()
            await autoSelectMatchingTarget()
            isLoading = false
        }
    }

    private func parseFile(_ fileURL: URL, withPassword password: String?) async -> (ParsedStatement?, Bool) {
        do {
            let format = fileFormat(for: fileURL)
            let fileName = fileURL.lastPathComponent
            let statement: ParsedStatement

            if let source = selectedSource, [.csv, .txt].contains(format) {
                if let parser = parserRegistry.parser(for: source) {
                    let rows = try CSVRowReader.read(from: fileURL)
                    statement = try parser.parse(rows: rows)
                } else {
                    statement = try await transactionImporter.parseStatement(from: fileURL, format: format)
                }
            } else if format == .pdf, let source = selectedSource, source == .hdfcBank || source == .hdfcCard,
                      let pwd = password
            {
                let pdfParser = FinanceParsers.HDFCPDFParser(password: pwd)
                statement = try await pdfParser.parseStatement(from: fileURL)
            } else {
                statement = try await transactionImporter.parseStatement(from: fileURL, format: format)
            }

            logger.info("Parsed \(fileName, privacy: .public): \(statement.transactions.count, privacy: .public) txns")
            return (statement, false)
        } catch let error as FinanceCore.TransactionImportError {
            if case .passwordProtected = error {
                passwordPromptFilename = fileURL.lastPathComponent
                isLoading = false
                return (nil, true)
            }
            errorMessage = "Error parsing \(fileURL.lastPathComponent): \(formatError(error))"
            parsedStatements = []
            isLoading = false
            return (nil, true)
        } catch {
            errorMessage = "Error parsing \(fileURL.lastPathComponent): \(error.localizedDescription)"
            parsedStatements = []
            isLoading = false
            return (nil, true)
        }
    }

    func retryParseFilesWithPassword(_ password: String, saveToKeychain: Bool) async {
        isLoading = true
        errorMessage = nil
        pdfPassword = password
        var statements: [ParsedStatement] = []

        for fileURL in fileURLs {
            let result = await parseFile(fileURL, withPassword: password)
            if let statement = result.0 {
                statements.append(statement)
            } else if result.1 {
                isPasswordInvalid = true
                return
            }
        }

        parsedStatements = statements
        passwordPromptFilename = nil
        await loadTargetsOnAppear()
        await autoSelectMatchingTarget()
        isLoading = false
    }

    func importTransactions() {
        Task {
            guard !fileURLs.isEmpty,
                  !parsedStatements.isEmpty,
                  let target = selectedTarget
            else {
                errorMessage = "Invalid import state"
                let filesOk = !fileURLs.isEmpty
                let stmtsOk = !parsedStatements.isEmpty
                let state = "files=\(filesOk), stmts=\(stmtsOk), target=\(selectedTarget != nil)"
                logger.error("Invalid state: \(state)")
                return
            }

            isLoading = true
            errorMessage = nil
            importResult = nil

            let fileCount = self.fileURLs.count
            let targetDesc = String(describing: target)
            logger.info(
                "Starting: \(fileCount, privacy: .public) files, target: \(targetDesc, privacy: .public)"
            )

            do {
                let result = try await performImport(target: target, fileCount: fileCount)
                importResult = result
                reset()
                isLoading = false
            } catch {
                let desc = error.localizedDescription
                logger.error("Import failed: \(desc, privacy: .public)")
                errorMessage = "Import failed: \(desc)"
                isLoading = false
            }
        }
    }
}

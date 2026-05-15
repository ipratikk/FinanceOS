import FinanceCore
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

private func formatError(_ error: TransactionImportError) -> String {
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

    var isLoading = false
    var errorMessage: String?
    var importResult: ImportResult?
    var passwordPromptFilename: String?

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
    let parserRegistry: StatementParserRegistry

    init(
        transactionImporter: any TransactionImporting,
        transactionImportPipeline: TransactionImportPipeline,
        bankRepository: any BankRepository,
        accountRepository: any AccountRepository,
        cardRepository: any CardRepository,
        transactionRepository: any TransactionRepository,
        parserRegistry: StatementParserRegistry
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
        fileURLs = urls
        errorMessage = nil
    }

    func parseFiles() {
        Task {
            guard !fileURLs.isEmpty else {
                errorMessage = "No files selected"
                logger.error("No file URLs provided")
                return
            }

            isLoading = true
            errorMessage = nil
            let fileCount = fileURLs.count
            logger.info("Starting parse of \(fileCount, privacy: .public) file(s)")

            var statements: [ParsedStatement] = []

            for fileURL in fileURLs {
                do {
                    let format = fileFormat(for: fileURL)
                    let fileName = fileURL.lastPathComponent
                    logger.debug("Parsing \(fileName, privacy: .public) as \(format.rawValue, privacy: .public)")

                    let statement = try await transactionImporter.parseStatement(
                        from: fileURL,
                        format: format
                    )

                    let txnCount = statement.transactions.count
                    logger.info("Parsed \(fileName, privacy: .public): \(txnCount, privacy: .public) txns")

                    statements.append(statement)
                } catch let error as TransactionImportError {
                    let fileName = fileURL.lastPathComponent
                    if case .passwordProtected = error {
                        passwordPromptFilename = fileName
                        isLoading = false
                        return
                    }
                    let formattedError = formatError(error)
                    logger.error("Parse error for \(fileName, privacy: .public): \(formattedError, privacy: .public)")
                    errorMessage = "Error parsing \(fileName): \(formattedError)"
                    parsedStatements = []
                    isLoading = false
                    return
                } catch {
                    let fileName = fileURL.lastPathComponent
                    let errorDesc = error.localizedDescription
                    logger.error("Parse error for \(fileName, privacy: .public): \(errorDesc, privacy: .public)")
                    errorMessage = "Error parsing \(fileName): \(errorDesc)"
                    parsedStatements = []
                    isLoading = false
                    return
                }
            }
            self.parsedStatements = statements
            await loadTargetsOnAppear()
            await autoSelectMatchingTarget()
            isLoading = false
        }
    }

    func retryParseFilesWithPassword(_ password: String, saveToKeychain: Bool) async {
        isLoading = true
        errorMessage = nil
        pdfPassword = password

        var statements: [ParsedStatement] = []

        for fileURL in fileURLs {
            do {
                let format = fileFormat(for: fileURL)
                let fileName = fileURL.lastPathComponent
                logger.debug("Retrying parse with password for \(fileName, privacy: .public)")

                let statement: ParsedStatement
                if format == .pdf {
                    let pdfParser = PDFStatementParser(password: password)
                    statement = try await pdfParser.parseStatement(from: fileURL)
                } else {
                    statement = try await transactionImporter.parseStatement(
                        from: fileURL,
                        format: format
                    )
                }

                let txnCount = statement.transactions.count
                logger.info("Parsed \(fileName, privacy: .public): \(txnCount, privacy: .public) txns")

                statements.append(statement)
            } catch let error as TransactionImportError {
                let fileName = fileURL.lastPathComponent
                let formattedError = formatError(error)
                logger.error("Parse error for \(fileName, privacy: .public): \(formattedError, privacy: .public)")
                errorMessage = "Error parsing \(fileName): \(formattedError)"
                parsedStatements = []
                isLoading = false
                return
            } catch {
                let fileName = fileURL.lastPathComponent
                let desc = error.localizedDescription
                logger.error("Parse error for \(fileName, privacy: .public): \(desc, privacy: .public)")
                errorMessage = "Error parsing \(fileName): \(error.localizedDescription)"
                parsedStatements = []
                isLoading = false
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

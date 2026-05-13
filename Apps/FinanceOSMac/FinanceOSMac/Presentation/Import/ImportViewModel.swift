import FinanceCore
import Foundation
import Observation
import OSLog

private let logger = FinanceLogger.importPipeline

@MainActor
@Observable
final class ImportViewModel {
    var fileURLs: [URL] = []
    var parsedStatements: [ParsedStatement] = []
    var selectedTarget: TransactionImportTarget?

    var isLoading = false
    var errorMessage: String?

    var accounts: [Account] = []
    var cards: [Card] = []

    var fileStatementPairs: [(url: URL, statement: ParsedStatement)] {
        zip(fileURLs, parsedStatements).map { ($0, $1) }
    }

    private let transactionImporter: any TransactionImporting
    private let transactionRepository: any TransactionRepository
    private let accountRepository: any AccountRepository
    private let cardRepository: any CardRepository

    init(
        transactionImporter: any TransactionImporting,
        transactionRepository: any TransactionRepository,
        accountRepository: any AccountRepository,
        cardRepository: any CardRepository
    ) {
        self.transactionImporter = transactionImporter
        self.transactionRepository = transactionRepository
        self.accountRepository = accountRepository
        self.cardRepository = cardRepository
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

            self.parsedStatements = statements
            loadTargets()

            isLoading = false
        }
    }

    func importTransactions() {
        Task {
            guard !fileURLs.isEmpty,
                  !parsedStatements.isEmpty,
                  let target = selectedTarget
            else {
                errorMessage = "Invalid import state"
                let filesOK = !self.fileURLs.isEmpty
                let statementsOK = !self.parsedStatements.isEmpty
                let targetOK = self.selectedTarget != nil
                let msg = "Invalid state: fileURLs=\(filesOK), stmts=\(statementsOK), target=\(targetOK)"
                logger.error("\(msg)")
                return
            }

            isLoading = true
            errorMessage = nil

            let fileCount = self.fileURLs.count
            let targetDesc = String(describing: target)
            logger.info("Starting: \(fileCount, privacy: .public) files, target: \(targetDesc, privacy: .public)")

            do {
                let transactions = try await processImportFiles(target: target)
                let txnCount = transactions.count
                logger.info("Saving \(txnCount, privacy: .public) txns to DB")
                try await transactionRepository.insertTransactions(transactions)

                logger.info("Imported \(txnCount, privacy: .public) txns from \(fileCount, privacy: .public) files")
                reset()
            } catch {
                logger.error("Import failed: \(error.localizedDescription, privacy: .public)")
                errorMessage = "Import failed: \(error.localizedDescription)"
                isLoading = false
            }
        }
    }

    private func processImportFiles(target: TransactionImportTarget) async throws -> [Transaction] {
        var allTransactions: [Transaction] = []

        for (index, fileURL) in fileURLs.enumerated() {
            let format = fileFormat(for: fileURL)
            let fileName = fileURL.lastPathComponent
            let fileNumber = index + 1
            let totalFiles = self.fileURLs.count

            logger.debug("Importing file \(fileNumber)/\(totalFiles): \(fileName, privacy: .public)")

            do {
                let transactions = try await transactionImporter.importTransactions(
                    from: fileURL,
                    format: format,
                    target: target
                )

                let txnCount = transactions.count
                logger.info("Got \(txnCount, privacy: .public) txns from \(fileName, privacy: .public)")
                allTransactions.append(contentsOf: transactions)
            } catch let error as TransactionImportError {
                let formattedError = formatError(error)
                logger.error("Import error for \(fileName, privacy: .public): \(formattedError, privacy: .public)")
                errorMessage = "Error importing \(fileName): \(formattedError)"
                isLoading = false
                throw error
            } catch {
                let desc = error.localizedDescription
                logger.error("Import error for \(fileName, privacy: .public): \(desc, privacy: .public)")
                errorMessage = "Error importing \(fileName): \(desc)"
                isLoading = false
                throw error
            }
        }

        return allTransactions
    }

    func loadTargetsOnAppear() async {
        do {
            logger.debug("Loading accounts and cards for selection")
            accounts = try await accountRepository.fetchAccounts()
            cards = try await cardRepository.fetchCards()
            let accountCount = accounts.count
            let cardCount = cards.count
            logger.debug("Loaded \(accountCount, privacy: .public) accounts and \(cardCount, privacy: .public) cards")
        } catch {
            let errorMsg = error.localizedDescription
            logger.error("Failed to load targets: \(errorMsg, privacy: .public)")
            errorMessage = errorMsg
        }
    }

    private func loadTargets() {
        Task {
            await loadTargetsOnAppear()
        }
    }

    private func fileFormat(for url: URL) -> StatementFileFormat {
        let pathExtension = url.pathExtension.lowercased()
        logger.debug("File extension: '\(pathExtension, privacy: .public)'")

        switch pathExtension {
        case "csv":
            return .csv
        case "xlsx":
            return .xlsx
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
        }
    }

    private func reset() {
        fileURLs = []
        parsedStatements = []
        selectedTarget = nil
        accounts = []
        cards = []
    }
}

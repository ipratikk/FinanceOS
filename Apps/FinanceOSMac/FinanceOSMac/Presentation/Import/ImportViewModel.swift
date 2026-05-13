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

            logger.info("Starting parse of \(self.fileURLs.count, privacy: .public) file(s)")

            var statements: [ParsedStatement] = []

            for fileURL in fileURLs {
                do {
                    let format = fileFormat(for: fileURL)
                    logger
                        .debug(
                            "Parsing \(fileURL.lastPathComponent, privacy: .public) as \(format.rawValue, privacy: .public)"
                        )

                    let statement = try await transactionImporter.parseStatement(
                        from: fileURL,
                        format: format
                    )

                    logger
                        .info(
                            "Successfully parsed \(fileURL.lastPathComponent, privacy: .public) with \(statement.transactions.count, privacy: .public) transactions"
                        )

                    statements.append(statement)
                } catch let error as TransactionImportError {
                    logger
                        .error(
                            "Import error for \(fileURL.lastPathComponent, privacy: .public): \(self.formatError(error), privacy: .public)"
                        )
                    errorMessage = "Error parsing \(fileURL.lastPathComponent): \(formatError(error))"
                    parsedStatements = []
                    isLoading = false
                    return
                } catch {
                    logger
                        .error(
                            "Unexpected error for \(fileURL.lastPathComponent, privacy: .public): \(error.localizedDescription, privacy: .public)"
                        )
                    errorMessage = "Error parsing \(fileURL.lastPathComponent): \(error.localizedDescription)"
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
                logger
                    .error(
                        "Invalid import state: fileURLs=\(!self.fileURLs.isEmpty), statements=\(!self.parsedStatements.isEmpty), target=\(self.selectedTarget != nil)"
                    )
                return
            }

            isLoading = true
            errorMessage = nil

            logger
                .info(
                    "Starting import of \(self.fileURLs.count, privacy: .public) file(s) to target: \(String(describing: target), privacy: .public)"
                )

            var allTransactions: [Transaction] = []

            for (index, fileURL) in fileURLs.enumerated() {
                do {
                    let format = fileFormat(for: fileURL)
                    logger
                        .debug(
                            "Importing file \(index + 1)/\(self.fileURLs.count): \(fileURL.lastPathComponent, privacy: .public)"
                        )

                    let transactions = try await transactionImporter.importTransactions(
                        from: fileURL,
                        format: format,
                        target: target
                    )

                    logger
                        .info(
                            "Got \(transactions.count, privacy: .public) transactions from \(fileURL.lastPathComponent, privacy: .public)"
                        )
                    allTransactions.append(contentsOf: transactions)
                } catch let error as TransactionImportError {
                    logger
                        .error(
                            "Import error for \(fileURL.lastPathComponent, privacy: .public): \(self.formatError(error), privacy: .public)"
                        )
                    errorMessage = "Error importing \(fileURL.lastPathComponent): \(formatError(error))"
                    isLoading = false
                    return
                } catch {
                    logger
                        .error(
                            "Unexpected error importing \(fileURL.lastPathComponent, privacy: .public): \(error.localizedDescription, privacy: .public)"
                        )
                    errorMessage = "Error importing \(fileURL.lastPathComponent): \(error.localizedDescription)"
                    isLoading = false
                    return
                }
            }

            do {
                logger.info("Saving \(allTransactions.count, privacy: .public) total transactions to DB")
                try await transactionRepository.insertTransactions(allTransactions)

                logger
                    .info(
                        "Successfully imported \(allTransactions.count, privacy: .public) transactions from \(self.fileURLs.count, privacy: .public) file(s)"
                    )
                reset()
            } catch {
                logger.error("Failed to save transactions: \(error.localizedDescription, privacy: .public)")
                errorMessage = "Failed to save transactions: \(error.localizedDescription)"
                isLoading = false
            }
        }
    }

    func loadTargetsOnAppear() async {
        do {
            logger.debug("Loading accounts and cards for selection")
            accounts = try await accountRepository.fetchAccounts()
            cards = try await cardRepository.fetchCards()
            let accountCount = accounts.count
            let cardCount = cards.count
            logger
                .debug(
                    "Loaded \(accountCount, privacy: .public) accounts and \(cardCount, privacy: .public) cards"
                )
        } catch {
            logger.error("Failed to load targets: \(error.localizedDescription, privacy: .public)")
            errorMessage = error.localizedDescription
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

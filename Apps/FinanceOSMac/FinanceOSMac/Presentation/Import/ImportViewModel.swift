import FinanceCore
import Foundation
import Observation
import OSLog

private let logger = FinanceLogger.importPipeline

@MainActor
@Observable
final class ImportViewModel {
    var fileURL: URL?
    var parsedStatement: ParsedStatement?
    var selectedTarget: TransactionImportTarget?

    var isLoading = false
    var errorMessage: String?

    var accounts: [Account] = []
    var cards: [Card] = []

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

    func setFileURL(_ url: URL) {
        fileURL = url
        errorMessage = nil
    }

    func parseFile() {
        Task {
            guard let fileURL else {
                errorMessage = "No file selected"
                logger.error("No file URL provided")
                return
            }

            isLoading = true
            errorMessage = nil

            logger.info("Starting parse: \(fileURL.lastPathComponent, privacy: .public)")

            do {
                let format = fileFormat(for: fileURL)
                logger.debug("Detected format: \(format.rawValue, privacy: .public)")

                let statement = try await transactionImporter.parseStatement(
                    from: fileURL,
                    format: format
                )

                logger
                    .info(
                        "Successfully parsed statement with \(statement.transactions.count, privacy: .public) transactions"
                    )
                logger
                    .debug(
                        "Institution: \(statement.institution, privacy: .public), Account: \(statement.accountName, privacy: .public)"
                    )

                self.parsedStatement = statement
                loadTargets()
            } catch let error as TransactionImportError {
                logger.error("Import error: \(self.formatError(error), privacy: .public)")
                errorMessage = formatError(error)
                parsedStatement = nil
            } catch {
                logger.error("Unexpected error: \(error.localizedDescription, privacy: .public)")
                errorMessage = error.localizedDescription
                parsedStatement = nil
            }

            isLoading = false
        }
    }

    func importTransactions() {
        Task {
            guard let fileURL,
                  let _ = parsedStatement,
                  let target = selectedTarget
            else {
                errorMessage = "Invalid import state"
                logger
                    .error(
                        "Invalid import state: fileURL=\(self.fileURL != nil), statement=\(self.parsedStatement != nil), target=\(self.selectedTarget != nil)"
                    )
                return
            }

            isLoading = true
            errorMessage = nil

            logger.info("Starting import to target: \(String(describing: target), privacy: .public)")

            do {
                let format = fileFormat(for: fileURL)
                logger.debug("Importing with format: \(format.rawValue, privacy: .public)")

                let transactions = try await transactionImporter.importTransactions(
                    from: fileURL,
                    format: format,
                    target: target
                )

                logger.info("Got \(transactions.count, privacy: .public) transactions, saving to DB")
                try await transactionRepository.insertTransactions(transactions)

                logger.info("Successfully imported \(transactions.count, privacy: .public) transactions")
                reset()
            } catch let error as TransactionImportError {
                logger.error("Import error: \(self.formatError(error), privacy: .public)")
                errorMessage = formatError(error)
            } catch {
                logger.error("Unexpected error during import: \(error.localizedDescription, privacy: .public)")
                errorMessage = error.localizedDescription
            }

            isLoading = false
        }
    }

    private func loadTargets() {
        Task {
            do {
                logger.debug("Loading accounts and cards for selection")
                accounts = try await accountRepository.fetchAccounts()
                cards = try await cardRepository.fetchCards()
                logger
                    .debug(
                        "Loaded \(self.accounts.count, privacy: .public) accounts and \(self.cards.count, privacy: .public) cards"
                    )
            } catch {
                logger.error("Failed to load targets: \(error.localizedDescription, privacy: .public)")
                errorMessage = error.localizedDescription
            }
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
        fileURL = nil
        parsedStatement = nil
        selectedTarget = nil
        accounts = []
        cards = []
    }
}

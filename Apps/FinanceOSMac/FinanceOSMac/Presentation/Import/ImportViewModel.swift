import FinanceCore
import Foundation
import Observation
import OSLog

let logger = FinanceLogger.importPipeline

private func fuzzyMatch(_ stored: String, _ parsed: String) -> Bool {
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

private func isSameTransaction(parsed: ParsedTransaction, existing: Transaction) -> Bool {
    transactionHash(parsed) == transactionHash(existing)
}

private func fileFormat(for url: URL) -> StatementFileFormat {
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

    private var pdfPassword: String?

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
                    let desc = error.localizedDescription
                    logger.error("Parse error for \(fileName, privacy: .public): \(desc, privacy: .public)")
                    errorMessage = "Error parsing \(fileName): \(error.localizedDescription)"
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

    private func performImport(
        target: TransactionImportTarget,
        fileCount: Int
    ) async throws -> ImportResult {
        var totalInserted = 0
        var totalSkipped = 0

        for (index, fileURL) in fileURLs.enumerated() {
            let format = fileFormat(for: fileURL)
            let fileName = fileURL.lastPathComponent
            let fileNumber = index + 1

            logger.debug("Importing file \(fileNumber)/\(fileCount): \(fileName, privacy: .public)")

            let result = try await transactionImportPipeline.execute(
                fileURL: fileURL,
                format: format,
                target: target
            )

            totalInserted += result.inserted
            totalSkipped += result.skipped
            logger.logInfo("File {file}: {inserted} inserted, {skipped} skipped", [
                "file": fileName,
                "inserted": result.inserted,
                "skipped": result.skipped
            ])
        }

        logger.logInfo("Import complete: {inserted} inserted, {skipped} skipped", [
            "inserted": totalInserted,
            "skipped": totalSkipped
        ])
        return ImportResult(inserted: totalInserted, skipped: totalSkipped)
    }

    func loadTargetsOnAppear() async {
        do {
            logger.debug("Loading accounts, cards, and banks")
            accounts = try await accountRepository.fetchAccounts()
            cards = try await cardRepository.fetchCards()
            banks = try await bankRepository.fetchBanks()
            logger.logDebug("Loaded {accounts} accounts, {cards} cards, and {banks} banks", [
                "accounts": accounts.count,
                "cards": cards.count,
                "banks": banks.count
            ])
        } catch {
            let errorMsg = error.localizedDescription
            logger.error("Failed to load targets: \(errorMsg, privacy: .public)")
            errorMessage = errorMsg
        }
    }

    private func autoSelectMatchingTarget() async {
        guard let statement = parsedStatements.first else { return }

        let isCard = statement.cardLast4 != nil
        let bankName = statement.bankName

        let matchingBank = banks.first { bank in
            fuzzyMatch(bank.name, bankName)
        }
        guard let bank = matchingBank else { return }

        if isCard, let cardLast4 = statement.cardLast4 {
            if let matchingCard = cards.first(where: { $0.bankId == bank.id && $0.cardLast4 == cardLast4 }) {
                selectedTarget = .card(matchingCard.id)
                logger.info("Auto-selected card: \(matchingCard.cardName, privacy: .public)")
                await detectDuplicates(for: .card(matchingCard.id))
            } else if let matchingCard = cards.first(where: { $0.bankId == bank.id }) {
                selectedTarget = .card(matchingCard.id)
                logger.info("Auto-selected card: \(matchingCard.cardName, privacy: .public)")
                await detectDuplicates(for: .card(matchingCard.id))
            }
        } else if !isCard, let accountLast4 = statement.accountLast4 {
            // swiftformat:disable all
            if let matchingAccount = accounts
                .first(where: { $0.bankId == bank.id && $0.accountLast4 == accountLast4 }) {
                selectedTarget = .account(matchingAccount.id)
                logger.info("Auto-selected account: \(matchingAccount.accountName, privacy: .public)")
                await detectDuplicates(for: .account(matchingAccount.id))
            } else if let matchingAccount = accounts.first(where: { $0.bankId == bank.id }) {
                selectedTarget = .account(matchingAccount.id)
                logger.info("Auto-selected account: \(matchingAccount.accountName, privacy: .public)")
                await detectDuplicates(for: .account(matchingAccount.id))
            }
            // swiftformat:enable all
        } else if !isCard {
            if let matchingAccount = accounts.first(where: { $0.bankId == bank.id }) {
                selectedTarget = .account(matchingAccount.id)
                logger.info("Auto-selected account: \(matchingAccount.accountName, privacy: .public)")
                await detectDuplicates(for: .account(matchingAccount.id))
            }
        }
    }

    private func detectDuplicates(for target: TransactionImportTarget) async {
        do {
            let existingTransactions: [Transaction] = switch target {
            case let .account(id):
                try await transactionRepository.fetchTransactionsForAccount(id)
            case let .card(id):
                try await transactionRepository.fetchTransactionsForCard(id)
            }

            duplicateTransactionIndices = []

            for (index, statement) in parsedStatements.enumerated() {
                for (txnIndex, parsedTxn) in statement.transactions.enumerated() {
                    // swiftformat:disable all
                    for existingTxn in existingTransactions
                        where isSameTransaction(parsed: parsedTxn, existing: existingTxn) {
                        let flatIndex = parsedStatements[..<index]
                            .reduce(0) { $0 + $1.transactions.count } + txnIndex
                        duplicateTransactionIndices.insert(flatIndex)
                    }
                    // swiftformat:enable all
                }
            }

            let dupCount = duplicateTransactionIndices.count
            logger.info("Found \(dupCount, privacy: .public) duplicate transactions")
        } catch {
            logger.error("Failed to detect duplicates: \(error.localizedDescription, privacy: .public)")
        }
    }

    private func reset() {
        fileURLs = []
        parsedStatements = []
        selectedTarget = nil
        importResult = nil
        accounts = []
        cards = []
        banks = []
    }
}

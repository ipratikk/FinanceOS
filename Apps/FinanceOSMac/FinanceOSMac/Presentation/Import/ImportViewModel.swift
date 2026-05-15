import FinanceCore
import Foundation
import Observation
import OSLog

private let logger = FinanceLogger.importPipeline

private func logInfo(_ staticMsg: StaticString, _ attrs: [String: CustomStringConvertible]) {
    var msg = staticMsg.withUTF8Buffer { String(decoding: $0, as: UTF8.self) }
    for (key, value) in attrs {
        msg = msg.replacingOccurrences(of: "{\(key)}", with: String(describing: value))
    }
    logger.info("\(msg, privacy: .public)")
}

private func logDebug(_ staticMsg: StaticString, _ attrs: [String: CustomStringConvertible]) {
    var msg = staticMsg.withUTF8Buffer { String(decoding: $0, as: UTF8.self) }
    for (key, value) in attrs {
        msg = msg.replacingOccurrences(of: "{\(key)}", with: String(describing: value))
    }
    logger.debug("\(msg, privacy: .public)")
}

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
    case "xls":
        return .xls
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

@MainActor
@Observable
final class ImportViewModel {
    var fileURLs: [URL] = []
    var parsedStatements: [ParsedStatement] = []
    var selectedTarget: TransactionImportTarget?

    var isLoading = false
    var errorMessage: String?
    var importResult: ImportResult?

    var accounts: [Account] = []
    var cards: [Card] = []
    var banks: [Bank] = []
    var duplicateTransactionIndices: Set<Int> = []

    var fileStatementPairs: [(url: URL, statement: ParsedStatement)] {
        zip(fileURLs, parsedStatements).map { ($0, $1) }
    }

    var supportedSources: [(bankName: String, sourceType: StatementSourceType)] {
        parserRegistry.supportedSources
    }

    private let transactionImporter: any TransactionImporting
    private let transactionImportPipeline: TransactionImportPipeline
    private let bankRepository: any BankRepository
    private let accountRepository: any AccountRepository
    private let cardRepository: any CardRepository
    private let transactionRepository: any TransactionRepository
    private let parserRegistry: StatementParserRegistry

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
            importResult = nil

            let fileCount = self.fileURLs.count
            let targetDesc = String(describing: target)
            logger.info("Starting: \(fileCount, privacy: .public) files, target: \(targetDesc, privacy: .public)")

            do {
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
                    logInfo("File {file}: {inserted} inserted, {skipped} skipped", [
                        "file": fileName,
                        "inserted": result.inserted,
                        "skipped": result.skipped
                    ])
                }

                importResult = ImportResult(inserted: totalInserted, skipped: totalSkipped)
                logInfo("Import complete: {inserted} inserted, {skipped} skipped", [
                    "inserted": totalInserted,
                    "skipped": totalSkipped
                ])
                reset()
                isLoading = false
            } catch {
                logger.error("Import failed: \(error.localizedDescription, privacy: .public)")
                errorMessage = "Import failed: \(error.localizedDescription)"
                isLoading = false
            }
        }
    }

    func loadTargetsOnAppear() async {
        do {
            logger.debug("Loading accounts, cards, and banks")
            accounts = try await accountRepository.fetchAccounts()
            cards = try await cardRepository.fetchCards()
            banks = try await bankRepository.fetchBanks()
            logDebug("Loaded {accounts} accounts, {cards} cards, and {banks} banks", [
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
            if let matchingAccount = accounts
                .first(where: { $0.bankId == bank.id && $0.accountLast4 == accountLast4 })
            {
                selectedTarget = .account(matchingAccount.id)
                logger.info("Auto-selected account: \(matchingAccount.accountName, privacy: .public)")
                await detectDuplicates(for: .account(matchingAccount.id))
            } else if let matchingAccount = accounts.first(where: { $0.bankId == bank.id }) {
                selectedTarget = .account(matchingAccount.id)
                logger.info("Auto-selected account: \(matchingAccount.accountName, privacy: .public)")
                await detectDuplicates(for: .account(matchingAccount.id))
            }
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
                    for existingTxn in existingTransactions {
                        if isSameTransaction(parsed: parsedTxn, existing: existingTxn) {
                            let flatIndex = parsedStatements[..<index]
                                .reduce(0) { $0 + $1.transactions.count } + txnIndex
                            duplicateTransactionIndices.insert(flatIndex)
                        }
                    }
                }
            }

            let dupCount = duplicateTransactionIndices.count
            logger.info("Found \(dupCount, privacy: .public) duplicate transactions")
        } catch {
            logger.error("Failed to detect duplicates: \(error.localizedDescription, privacy: .public)")
        }
    }

    func createTargetFromDetected(
        customName: String? = nil,
        nickname: String = "",
        last4: String = "",
        bankID: UUID? = nil,
        accountType: AccountType = .savings,
        cardType: CardType = .other,
        isCard: Bool? = nil
    ) async {
        guard let statement = parsedStatements.first else {
            errorMessage = "No parsed statements available"
            return
        }

        do {
            let bank = try await resolveOrCreateBank(
                for: statement,
                providedBankID: bankID
            )
            let isCardTarget = isCard ?? (statement.cardLast4 != nil)
            if isCardTarget {
                try await createCard(bank, statement, customName, last4, cardType, nickname)
            } else {
                try await createAccount(bank, statement, customName, last4, accountType, nickname)
            }
        } catch {
            let errorDesc = error.localizedDescription
            logger.error("Failed to create target: \(errorDesc)")
            errorMessage = "Failed to create target: \(errorDesc)"
        }
    }

    private func resolveOrCreateBank(
        for statement: ParsedStatement,
        providedBankID: UUID?
    ) async throws -> Bank {
        let detectedBankName = statement.bankName
        if let providedBankID,
           let found = try await bankRepository.fetchBanks()
           .first(where: { $0.id == providedBankID })
        {
            return found
        }
        let existingBanks = try await bankRepository.fetchBanks()
        if let existingBank = existingBanks.first(where: { $0.name == detectedBankName }) {
            return existingBank
        }
        let newBank = Bank(name: detectedBankName, providerType: .bank)
        try await bankRepository.insert(newBank)
        return newBank
    }

    private func createCard(
        _ bank: Bank,
        _ statement: ParsedStatement,
        _ customName: String?,
        _ last4: String,
        _ cardType: CardType,
        _ nickname: String
    ) async throws {
        let cardName = customName ??
            (statement.cardLast4
                .map { "\(statement.bankName) Card - \($0)" } ??
                "\(statement.bankName) Card")
        let card = Card(
            bankId: bank.id,
            linkedAccountId: nil,
            cardName: cardName,
            cardLast4: last4,
            cardType: cardType,
            nickname: nickname
        )
        try await cardRepository.insert(card)
        selectedTarget = .card(card.id)
        cards.append(card)
        logger.info("Created card: \(cardName)")
    }

    private func createAccount(
        _ bank: Bank,
        _ statement: ParsedStatement,
        _ customName: String?,
        _ last4: String,
        _ accountType: AccountType,
        _ nickname: String
    ) async throws {
        let accountName = customName ??
            (statement.accountName.isEmpty ?
                "\(statement.bankName) Account" :
                statement.accountName)
        let account = Account(
            bankId: bank.id,
            accountName: accountName,
            accountLast4: last4,
            accountType: accountType,
            nickname: nickname
        )
        try await accountRepository.insert(account)
        selectedTarget = .account(account.id)
        accounts.append(account)
        logger.info("Created account: \(accountName)")
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

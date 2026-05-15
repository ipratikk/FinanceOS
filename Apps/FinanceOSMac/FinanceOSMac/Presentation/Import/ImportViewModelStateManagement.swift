import FinanceCore
import Foundation
import OSLog

extension ImportViewModel {
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

    func performImport(
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

            let result: ImportResult
            if format == .pdf {
                guard index < parsedStatements.count else {
                    throw TransactionImportError.malformedFile("Parsed statement not available")
                }
                result = try await importStatement(parsedStatements[index], target: target)
            } else {
                result = try await transactionImportPipeline.execute(
                    fileURL: fileURL,
                    format: format,
                    target: target
                )
            }

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

    private func importStatement(
        _ statement: ParsedStatement,
        target: TransactionImportTarget
    ) async throws -> ImportResult {
        let transactions = statement.transactions.map { parsedTxn in
            let accountID: UUID?
            let cardID: UUID?

            switch target {
            case let .account(id):
                accountID = id
                cardID = nil
            case let .card(id):
                accountID = nil
                cardID = id
            }

            return Transaction(
                accountID: accountID,
                cardID: cardID,
                postedAt: parsedTxn.postedAt,
                description: parsedTxn.description,
                amountMinorUnits: abs(parsedTxn.amountMinorUnits),
                currencyCode: parsedTxn.currencyCode,
                transactionType: parsedTxn.amountMinorUnits < 0 ? .debit : .credit,
                sourceFingerprint: parsedTxn.sourceFingerprint
            )
        }

        return try await transactionRepository.insertTransactions(transactions)
    }

    func autoSelectMatchingTarget() async {
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

    func detectDuplicates(for target: TransactionImportTarget) async {
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

    func reset() {
        fileURLs = []
        parsedStatements = []
        selectedTarget = nil
        importResult = nil
        accounts = []
        cards = []
        banks = []
    }
}

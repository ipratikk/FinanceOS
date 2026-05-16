import FinanceCore
import FinanceParsers
import Foundation
import OSLog

extension ImportViewModel {
    func loadTargetsOnAppear() async {
        do {
            logger.debug("Loading ledgers and banks")
            ledgers = try await ledgerRepository.fetchLedgers()
            banks = try await bankRepository.fetchBanks()
            logger.logDebug("Loaded {ledgers} ledgers and {banks} banks", [
                "ledgers": ledgers.count,
                "banks": banks.count
            ])
        } catch {
            let errorMsg = error.localizedDescription
            logger.error("Failed to load targets: \(errorMsg, privacy: .public)")
            importSession.errorMessage = errorMsg
        }
    }

    func performImport(
        target: TransactionImportTarget,
        fileCount: Int
    ) async throws -> ImportResult {
        var totalInserted = 0
        var totalSkipped = 0

        for (index, fileURL) in importSession.fileURLs.enumerated() {
            let fileName = fileURL.lastPathComponent
            let fileNumber = index + 1

            logger.debug("Importing file \(fileNumber)/\(fileCount): \(fileName, privacy: .public)")

            guard index < importSession.parsedStatements.count else {
                throw FinanceCore.TransactionImportError.malformedFile("Parsed statement not available")
            }

            let result = try await transactionImportPipeline.execute(
                statement: importSession.parsedStatements[index],
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

    func autoSelectMatchingTarget() async {
        guard let statement = importSession.parsedStatements.first else { return }

        do {
            let matchResult = try await accountMatcher.findMatches(for: statement)
            switch matchResult {
            case let .exactMatch(ledger):
                importSession.selectedTarget = .ledger(ledger.id)
                logger.info("Auto-matched exact account")
                await detectDuplicates(for: .ledger(ledger.id))
            case let .fuzzyMatch(ledger):
                importSession.selectedTarget = .ledger(ledger.id)
                logger.info("Auto-matched fuzzy account")
                await detectDuplicates(for: .ledger(ledger.id))
            case .noMatch:
                logger.info("No matching account found, user will create new")
            }
        } catch {
            logger.error("Account matching failed: \(error.localizedDescription)")
            if let target = FinanceCore.ImportTargetMatcher.bestTarget(
                for: statement,
                ledgers: ledgers,
                banks: banks
            ) {
                importSession.selectedTarget = target
                await detectDuplicates(for: target)
            }
        }
    }

    func detectDuplicates(for target: TransactionImportTarget) async {
        do {
            let allTransactions = try await transactionRepository.fetchTransactions()

            if case let .ledger(ledgerId) = target {
                let existingTransactions = allTransactions.filter { $0.ledgerId == ledgerId }
                duplicateTransactionIndices = []

                for (index, statement) in importSession.parsedStatements.enumerated() {
                    for (txnIndex, parsedTxn) in statement.transactions.enumerated() {
                        // swiftformat:disable all
                        for existingTxn in existingTransactions
                            where FinanceCore.TransactionDeduplicator.isSame(parsed: parsedTxn, existing: existingTxn) {
                            let flatIndex = importSession.parsedStatements[..<index]
                                .reduce(0) { $0 + $1.transactions.count } + txnIndex
                            duplicateTransactionIndices.insert(flatIndex)
                        }
                        // swiftformat:enable all
                    }
                }

                let dupCount = duplicateTransactionIndices.count
                logger.info("Found \(dupCount, privacy: .public) duplicate transactions")
            }
        } catch {
            logger.error("Failed to detect duplicates: \(error.localizedDescription, privacy: .public)")
        }
    }

    func reset() {
        importSession.reset()
        ledgers = []
        banks = []
        duplicateTransactionIndices = []
    }
}

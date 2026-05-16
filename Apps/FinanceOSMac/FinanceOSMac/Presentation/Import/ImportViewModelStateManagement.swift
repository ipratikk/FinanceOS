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
            let fileName = fileURL.lastPathComponent
            let fileNumber = index + 1

            logger.debug("Importing file \(fileNumber)/\(fileCount): \(fileName, privacy: .public)")

            guard index < parsedStatements.count else {
                throw FinanceCore.TransactionImportError.malformedFile("Parsed statement not available")
            }

            let result = try await transactionImportPipeline.execute(
                statement: parsedStatements[index],
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
        guard let statement = parsedStatements.first else { return }

        if let target = FinanceCore.ImportTargetMatcher.bestTarget(
            for: statement,
            ledgers: ledgers,
            banks: banks
        ) {
            selectedTarget = target
            logger.info("Auto-selected target")
            await detectDuplicates(for: target)
        }
    }

    func detectDuplicates(for target: TransactionImportTarget) async {
        do {
            let allTransactions = try await transactionRepository.fetchTransactions()

            if case let .ledger(ledgerId) = target {
                let existingTransactions = allTransactions.filter { $0.ledgerId == ledgerId }
                duplicateTransactionIndices = []

                for (index, statement) in parsedStatements.enumerated() {
                    for (txnIndex, parsedTxn) in statement.transactions.enumerated() {
                        // swiftformat:disable all
                        for existingTxn in existingTransactions
                            where FinanceCore.TransactionDeduplicator.isSame(parsed: parsedTxn, existing: existingTxn) {
                            let flatIndex = parsedStatements[..<index]
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
        fileURLs = []
        parsedStatements = []
        selectedTarget = nil
        importResult = nil
        ledgers = []
        banks = []
    }
}

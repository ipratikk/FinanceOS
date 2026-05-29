import FinanceCore
import FinanceParsers
import FinanceUI
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
        let context = OperationContext.importSession()
        var totalInserted = 0
        var totalSkipped = 0

        for (index, fileURL) in importSession.fileURLs.enumerated() {
            let fileName = fileURL.lastPathComponent
            let fileNumber = index + 1

            logger.debug("Importing file \(fileNumber)/\(fileCount): \(fileName, privacy: .public)")

            guard index < importSession.parsedStatements.count else {
                throw FinanceCore.TransactionImportError.malformedFile("Parsed statement not available")
            }

            let ledgerKind: LedgerKind
            if case let .ledger(ledgerId) = target {
                guard let found = ledgers.first(where: { $0.id == ledgerId }) else {
                    throw ImportError.targetNotFound(ledgerId)
                }
                ledgerKind = found.kind
            } else {
                ledgerKind = .bankAccount
            }

            let statement = importSession.parsedStatements[index]
            let result = try await transactionImportPipeline.execute(
                statement: statement,
                target: target,
                ledgerKind: ledgerKind,
                context: context
            )

            try await applyStatementMetadata(statement.metadata, to: target)

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

    private func applyStatementMetadata(
        _ metadata: FinanceParsers.StatementMetadata?,
        to target: TransactionImportTarget
    ) async throws {
        guard case let .ledger(ledgerId) = target else { return }
        if let openingBalance = metadata?.openingBalance,
           let ledger = try await ledgerRepository.fetchLedger(id: ledgerId),
           ledger.openingBalance == nil {
            try await ledgerRepository.updateOpeningBalance(id: ledgerId, balance: openingBalance)
        }
        if let closingBalance = metadata?.closingBalance,
           let statementDate = metadata?.generatedAt {
            try await ledgerRepository.updateClosingBalance(id: ledgerId, balance: closingBalance, asOf: statementDate)
        }
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

    func detectDuplicates(for target: TransactionImportTarget?) async {
        var existingTransactions: [Transaction] = []
        if case let .ledger(ledgerId) = target {
            do {
                let all = try await transactionRepository.fetchTransactions()
                existingTransactions = all.filter { $0.ledgerId == ledgerId }
            } catch {
                logger.logError("Failed to fetch transactions: {error}", ["error": error.localizedDescription])
            }
        }

        let (skipAll, inDB) = await detectDuplicatesOptimized(
            parsedStatements: importSession.parsedStatements,
            existingTransactions: existingTransactions
        )
        duplicateTransactionIndices = skipAll
        alreadyInDBIndices = inDB
    }

    private func detectDuplicatesOptimized(
        parsedStatements: [ParsedStatement],
        existingTransactions: [Transaction]
    ) async -> (skipAll: Set<Int>, inDB: Set<Int>) {
        var skipAll = Set<Int>()
        var inDB = Set<Int>()
        let existingHashes = Set(existingTransactions.map { hashTransaction($0) })
        var seen = Set<String>()

        var flatIndex = 0
        for statement in parsedStatements {
            for parsedTxn in statement.transactions {
                let hash = hashParsedTransaction(parsedTxn)
                let isFirstSeen = seen.insert(hash).inserted
                if !isFirstSeen {
                    skipAll.insert(flatIndex)
                } else if existingHashes.contains(hash) {
                    skipAll.insert(flatIndex)
                    inDB.insert(flatIndex)
                }
                flatIndex += 1
            }
        }

        logger.logInfo(
            "Dedup: {indb} in DB, {batch} batch-only, {new} new",
            [
                "indb": String(inDB.count),
                "batch": String(skipAll.count - inDB.count),
                "new": String(flatIndex - skipAll.count)
            ]
        )
        return (skipAll, inDB)
    }

    private func hashParsedTransaction(_ txn: ParsedTransaction) -> String {
        txn.sourceFingerprint
    }

    private func hashTransaction(_ txn: Transaction) -> String {
        if let fp = txn.sourceFingerprint { return fp }
        let dateStr = FormatterCache.iso8601.string(from: Calendar.current.startOfDay(for: txn.postedAt))
        let descStr = txn.description
            .components(separatedBy: .whitespaces).filter { !$0.isEmpty }.joined().lowercased()
        return "\(dateStr)|\(String(abs(txn.amountMinorUnits)))|\(descStr)"
    }

    func reset() {
        importSession.reset()
        ledgers = []
        banks = []
        duplicateTransactionIndices = []
        alreadyInDBIndices = []
    }

    // MARK: - Step Navigation

    func selectSourceAndAdvance(_ source: StatementSource) {
        setSource(source)
        currentStep = .upload
    }

    func advanceToReview() {
        currentStep = .review
    }

    func resetToSource() {
        reset()
        currentStep = .source
    }

    func backToUpload() {
        parsedStatements = []
        selectedTarget = nil
        duplicateTransactionIndices = []
        alreadyInDBIndices = []
        currentStep = .upload
    }
}

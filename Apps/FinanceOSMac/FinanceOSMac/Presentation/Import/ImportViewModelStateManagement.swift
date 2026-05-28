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

    func detectDuplicates(for target: TransactionImportTarget) async {
        do {
            let allTransactions = try await transactionRepository.fetchTransactions()

            if case let .ledger(ledgerId) = target {
                let existingTransactions = allTransactions.filter { $0.ledgerId == ledgerId }
                duplicateTransactionIndices = []

                let duplicates = await detectDuplicatesOptimized(
                    parsedStatements: importSession.parsedStatements,
                    existingTransactions: existingTransactions
                )

                duplicateTransactionIndices = duplicates
                let dupCount = duplicateTransactionIndices.count
                logger.logInfo(
                    "Found {count} duplicate transactions out of {total}",
                    [
                        "count": String(dupCount),
                        "total": String(importSession.parsedStatements.reduce(0) { $0 + $1.transactions.count })
                    ]
                )
            }
        } catch {
            logger.logError("Failed to detect duplicates: {error}", ["error": error.localizedDescription])
        }
    }

    private func detectDuplicatesOptimized(
        parsedStatements: [ParsedStatement],
        existingTransactions: [Transaction]
    ) async -> Set<Int> {
        var duplicates = Set<Int>()
        var nonMatches: [(Int, String)] = []

        let existingHashes = Set(
            existingTransactions.map { hashTransaction($0) }
        )

        var flatIndex = 0
        for statement in parsedStatements {
            for parsedTxn in statement.transactions {
                let hash = hashParsedTransaction(parsedTxn)
                if existingHashes.contains(hash) {
                    duplicates.insert(flatIndex)
                } else {
                    nonMatches.append((flatIndex, parsedTxn.description))
                }
                flatIndex += 1
            }
        }

        if !nonMatches.isEmpty {
            logDuplicateDebugInfo(
                duplicates: duplicates,
                nonMatches: nonMatches,
                flatIndex: flatIndex,
                parsedStatements: parsedStatements,
                existingTransactions: existingTransactions
            )
        }

        return duplicates
    }

    private func logDuplicateDebugInfo(
        duplicates: Set<Int>,
        nonMatches: [(Int, String)],
        flatIndex: Int,
        parsedStatements: [ParsedStatement],
        existingTransactions: [Transaction]
    ) {
        logger.logWarning(
            "Duplicate detection: {matched}/{total} matched, {unmatched} not found",
            [
                "matched": String(duplicates.count),
                "total": String(flatIndex),
                "unmatched": String(nonMatches.count)
            ]
        )

        let existingUpiTxns = existingTransactions.filter { $0.description.contains("UPI") }
        logger.logDebug(
            "Database has {count} UPI transactions",
            ["count": String(existingUpiTxns.count)]
        )

        if let firstUpi = existingUpiTxns.first {
            logger.logDebug(
                "Example stored UPI: len={len} desc={desc}",
                ["len": String(firstUpi.description.count), "desc": firstUpi.description]
            )
        }

        let samples = nonMatches.prefix(1)
        for (idx, parsedDesc) in samples {
            debugParsedTransactionSample(
                idx: idx,
                parsedDesc: parsedDesc,
                parsedStatements: parsedStatements,
                existingTransactions: existingTransactions
            )
        }
    }

    private func debugParsedTransactionSample(
        idx: Int,
        parsedDesc: String,
        parsedStatements: [ParsedStatement],
        existingTransactions: [Transaction]
    ) {
        logger.logDebug(
            "Example parsed UPI: len={len} desc={desc}",
            ["len": String(parsedDesc.count), "desc": parsedDesc]
        )

        var flatIdx = 0
        for statement in parsedStatements {
            for parsedTxn in statement.transactions {
                if flatIdx == idx {
                    logger.logDebug(
                        "Parsed txn details: date={date} amount={amt}",
                        [
                            "date": ISO8601DateFormatter().string(from: parsedTxn.postedAt),
                            "amt": String(parsedTxn.amountMinorUnits)
                        ]
                    )
                }
                flatIdx += 1
            }
        }

        let keyword = parsedDesc.prefix(20)
        let storedMatches = existingTransactions.filter {
            $0.description.prefix(20) == keyword
        }
        if let match = storedMatches.first {
            logger.logDebug(
                "Found similar stored: len={len} desc={desc}",
                ["len": String(match.description.count), "desc": match.description]
            )

            let storedHash = hashTransaction(match)
            logger.logDebug("Stored hash: {sh}", ["sh": storedHash])
            logger.logDebug(
                "Match details: date={date} amount={amt}",
                [
                    "date": ISO8601DateFormatter().string(from: match.postedAt),
                    "amt": String(match.amountMinorUnits)
                ]
            )
        }
    }

    private func hashParsedTransaction(_ txn: ParsedTransaction) -> String {
        let dateStr = ISO8601DateFormatter().string(
            from: Calendar.current.startOfDay(for: txn.postedAt)
        )
        let amountStr = String(abs(txn.amountMinorUnits))
        let descStr = txn.description.trimmingCharacters(in: .whitespaces).lowercased()
        return "\(dateStr)|\(amountStr)|\(descStr)"
    }

    private func hashTransaction(_ txn: Transaction) -> String {
        let dateStr = ISO8601DateFormatter().string(
            from: Calendar.current.startOfDay(for: txn.postedAt)
        )
        let amountStr = String(abs(txn.amountMinorUnits))
        let descStr = txn.description.trimmingCharacters(in: .whitespaces).lowercased()
        return "\(dateStr)|\(amountStr)|\(descStr)"
    }

    func reset() {
        importSession.reset()
        ledgers = []
        banks = []
        duplicateTransactionIndices = []
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
        currentStep = .upload
    }
}

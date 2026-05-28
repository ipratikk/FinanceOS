import FinanceCore
import FinanceIntelligence
import Foundation
import Observation

@MainActor
@Observable
final class TransactionsViewModel {
    private let transactionRepository: TransactionRepository
    private let ledgerRepository: LedgerRepository
    private let intelligenceService: (any TransactionIntelligenceService)?

    var transactionRows: [TransactionRow] = []
    var listState = TransactionListState()
    var isLoading = false
    var isAnalyzing = false
    var deleteError: String?

    private var rawTransactions: [Transaction] = []
    private var cachedLedgers: [Ledger] = []

    var sections: [TransactionSection] {
        listState.sections(from: transactionRows)
    }

    init(
        transactionRepository: TransactionRepository,
        ledgerRepository: LedgerRepository,
        intelligenceService: (any TransactionIntelligenceService)? = nil
    ) {
        self.transactionRepository = transactionRepository
        self.ledgerRepository = ledgerRepository
        self.intelligenceService = intelligenceService
    }

    func loadTransactions() async {
        isLoading = true
        defer { isLoading = false }

        do {
            rawTransactions = try await transactionRepository.fetchTransactions()
            cachedLedgers = try await ledgerRepository.fetchLedgers()
            // Use DB-cached categoryId/merchantName immediately — no lag on returning launches.
            transactionRows = makeRows(transactions: rawTransactions, results: [:])
            listState.updateAvailableYears(from: transactionRows)
        } catch {
            FinanceLogger.userInterface.logError("Failed to load transactions", caughtError: error, [:])
        }

        Task.detached(priority: .background) { [weak self] in
            await self?.analyzeUncategorized()
        }
    }

    func deleteTransaction(id: UUID) async {
        do {
            deleteError = nil
            try await transactionRepository.delete(id: id)
            await loadTransactions()
        } catch {
            deleteError = error.localizedDescription
        }
    }

    /// Called when the user corrects a category. Updates memory + persists to DB.
    func applyCorrection(transactionId: UUID, correctedCategoryId: String) async {
        // Update row in memory immediately
        if let idx = transactionRows.firstIndex(where: { $0.id == transactionId }) {
            let old = transactionRows[idx]
            transactionRows[idx] = TransactionRow(
                id: old.id, title: old.title, subtitle: old.subtitle,
                amountText: old.amountText, transactionType: old.transactionType,
                postedAt: old.postedAt, merchantName: old.merchantName,
                categoryId: correctedCategoryId, isUserCorrected: true,
                sourceTransaction: old.sourceTransaction
            )
        }
        // Persist to DB so next launch reads the corrected value directly
        do {
            try await transactionRepository.updateIntelligence(
                id: transactionId, categoryId: correctedCategoryId, merchantName: nil
            )
        } catch {
            FinanceLogger.userInterface.logError("Failed to persist correction", caughtError: error, [:])
        }
    }
}

// MARK: - Intelligence

private extension TransactionsViewModel {
    func analyzeUncategorized() async {
        guard let service = intelligenceService else { return }
        let allTransactions = await MainActor.run { rawTransactions }

        // Only analyze transactions not yet in the DB cache.
        // Corrected transactions have categoryId set by applyCorrection → also skipped.
        let uncategorized = allTransactions.filter { $0.categoryId == nil }
        guard !uncategorized.isEmpty else { return }

        await MainActor.run { isAnalyzing = true }
        do {
            let results = try await service.analyzeBatch(uncategorized, context: .empty)
            let byId = Dictionary(uniqueKeysWithValues: results.map { ($0.transaction.id, $0) })

            // Persist new results to DB for future launches (no re-analysis needed next time).
            for result in results {
                try? await MainActor.run { transactionRepository }.updateIntelligence(
                    id: result.transaction.id,
                    categoryId: result.categoryPrediction.categoryId,
                    merchantName: result.merchantCandidate.canonicalName
                )
            }

            let ledgers = await MainActor.run { cachedLedgers }
            let updated = makeRows(transactions: allTransactions, results: byId, ledgers: ledgers)
            await MainActor.run {
                transactionRows = updated
                isAnalyzing = false
            }
        } catch {
            await MainActor.run {
                FinanceLogger.userInterface.logError("Intelligence analysis failed", caughtError: error, [:])
                isAnalyzing = false
            }
        }
    }
}

// MARK: - Row Building

private extension TransactionsViewModel {
    func makeRows(
        transactions: [Transaction],
        results: [UUID: AnalyzedTransaction],
        ledgers: [Ledger]? = nil
    ) -> [TransactionRow] {
        let ledgersByID = Dictionary(uniqueKeysWithValues: (ledgers ?? cachedLedgers).map { ($0.id, $0) })
        return transactions.map { transaction in
            let sourceName = transaction.ledgerId.flatMap { ledgersByID[$0] }?.displayName ?? "Unknown Source"
            let analyzed = results[transaction.id]
            // Prefer fresh intelligence result; fall back to DB-cached values.
            let categoryId = analyzed?.categoryPrediction.categoryId ?? transaction.categoryId
            let merchantName = analyzed?.merchantCandidate.canonicalName ?? transaction.merchantName
            return TransactionRow(
                id: transaction.id,
                title: transaction.description,
                subtitle: sourceName,
                amountText: amountText(
                    minorUnits: transaction.amountMinorUnits,
                    currencyCode: transaction.currencyCode,
                    transactionType: transaction.transactionType
                ),
                transactionType: transaction.transactionType,
                postedAt: transaction.postedAt,
                merchantName: merchantName,
                categoryId: categoryId,
                isUserCorrected: analyzed?.isUserCorrected ?? false,
                sourceTransaction: transaction
            )
        }
    }

    func amountText(minorUnits: Int64, currencyCode: String, transactionType: TransactionType) -> String {
        let whole = minorUnits / 100
        let frac = minorUnits % 100
        let sign = transactionType == .debit ? "-" : "+"
        let symbol = CurrencySymbol.symbol(for: currencyCode)
        return "\(sign)\(symbol)\(whole).\(String(format: "%02d", frac))"
    }
}

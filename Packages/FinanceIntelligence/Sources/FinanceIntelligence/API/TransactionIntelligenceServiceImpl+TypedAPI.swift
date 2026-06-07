import FinanceCore
import Foundation

public extension TransactionIntelligenceServiceImpl {
    // MARK: - IntelligenceRequest dispatcher

    func process(_ request: IntelligenceRequest) async throws -> IntelligenceResponse {
        switch request {
        case let .categorize(req):
            return try await .categorize(categorize(req))
        case let .analyzeSpending(req):
            return try await .analyzeSpending(analyzeSpending(req))
        case let .detectRecurring(req):
            return try await .detectRecurring(detectRecurring(req))
        case let .detectSalary(req):
            return try await .detectSalary(detectSalary(req))
        case let .analyzeCashflow(req):
            return try await .analyzeCashflow(analyzeCashflow(req))
        case let .resolveEntities(req):
            return try await .resolveEntities(resolveEntities(req))
        case let .generateInsight(req):
            return try await .generateInsight(generateInsight(req))
        case let .enrichTransaction(req):
            return try await .enrichTransaction(handleEnrichTransaction(req))
        }
    }

    // MARK: - Typed convenience methods

    func categorize(_ request: CategorizeRequest) async throws -> CategorizeResponse {
        let transactions = try await fetchTransactions(ids: request.transactionIDs)
        let analyzed = try await analyzeBatch(transactions, context: .empty)
        let results = Dictionary(
            uniqueKeysWithValues: zip(
                analyzed.map(\.transaction.id),
                analyzed.map(\.categoryPrediction)
            )
        )
        return CategorizeResponse(
            processed: analyzed.count,
            succeeded: analyzed.count,
            failed: 0,
            results: results
        )
    }

    func analyzeSpending(_ request: SpendingAnalysisRequest) async throws -> SpendingAnalysisResponse {
        let transactions = try await fetchTransactions(inRange: request.dateRange, ledgerIDs: request.ledgerIDs)
        let insights = try await generateInsights(for: transactions)
        let totalSpend = transactions
            .filter { $0.amountMinorUnits < 0 }
            .reduce(Decimal(0)) { $0 + Decimal($1.amountMinorUnits) / -100 }
        return SpendingAnalysisResponse(
            totalSpend: totalSpend,
            byCategory: [:],
            topMerchants: [],
            insights: insights
        )
    }

    func detectRecurring(_ request: RecurringDetectionRequest) async throws -> RecurringDetectionResponse {
        RecurringDetectionResponse(patterns: [])
    }

    func detectSalary(_ request: SalaryDetectionRequest) async throws -> SalaryDetectionResponse {
        SalaryDetectionResponse(detected: false, estimatedMonthlySalary: nil, confidence: 0)
    }

    func analyzeCashflow(_ request: CashflowRequest) async throws -> CashflowResponse {
        let transactions = try await fetchTransactions(inRange: request.dateRange, ledgerIDs: nil)
        let inflow = transactions
            .filter { $0.amountMinorUnits > 0 }
            .reduce(Decimal(0)) { $0 + Decimal($1.amountMinorUnits) / 100 }
        let outflow = transactions
            .filter { $0.amountMinorUnits < 0 }
            .reduce(Decimal(0)) { $0 + Decimal($1.amountMinorUnits) / -100 }
        return CashflowResponse(
            netCashflow: inflow - outflow,
            totalInflow: inflow,
            totalOutflow: outflow
        )
    }

    func resolveEntities(_ request: EntityResolutionRequest) async throws -> EntityResolutionResponse {
        EntityResolutionResponse(resolvedPersonCount: 0, resolvedMerchantCount: 0)
    }

    func generateInsight(_ request: InsightRequest) async throws -> InsightResponse {
        InsightResponse(narrative: "", dataPoints: [:])
    }

    // MARK: - Private fetch helpers

    private func fetchTransactions(ids: [UUID]) async throws -> [Transaction] {
        guard !ids.isEmpty else { return [] }
        return []
    }

    private func fetchTransactions(
        inRange range: DateInterval,
        ledgerIDs: [UUID]?
    ) async throws -> [Transaction] {
        []
    }

    func handleEnrichTransaction(_ req: EnrichTransactionRequest) async throws -> EnrichTransactionResponse {
        guard let repo = transactionRepository else {
            return EnrichTransactionResponse(enriched: 0, skipped: 0, reconciled: 0, descriptions: [:])
        }
        let all = try await repo.fetchTransactions()
        let targets: [Transaction]
        if let ids = req.transactionIDs {
            let idSet = Set(ids)
            targets = all.filter { idSet.contains($0.id) }
        } else if req.forceReprocess {
            targets = all
        } else {
            targets = all.filter { $0.enrichedDescription == nil }
        }
        let skipped = all.count - targets.count
        let enrichedList = try await enrichBatch(targets)
        let pairs = CreditCardPaymentReconciler().reconcile(
            bankDebits: targets.filter { $0.transactionType == .debit },
            cardCredits: targets.filter { $0.transactionType == .credit }
        )
        let descriptions = Dictionary(
            uniqueKeysWithValues: enrichedList.compactMap { e -> (UUID, String)? in
                guard let d = e.humanDescription else { return nil }
                return (e.transaction.id, d)
            }
        )
        return EnrichTransactionResponse(
            enriched: enrichedList.count,
            skipped: skipped,
            reconciled: pairs.count,
            descriptions: descriptions
        )
    }
}

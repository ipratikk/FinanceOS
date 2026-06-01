import FinanceCore
@testable import FinanceIntelligence
import Foundation
import Testing

// MARK: - Helpers

private func makeTransaction(
    description: String,
    amountMinorUnits: Int64,
    daysAgo: Int,
    type: TransactionType = .debit
) -> Transaction {
    let date = Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date()) ?? Date()
    return Transaction(
        id: UUID(),
        ledgerId: nil,
        accountID: nil,
        cardID: nil,
        postedAt: date,
        description: description,
        amountMinorUnits: amountMinorUnits,
        currencyCode: "INR",
        transactionType: type,
        sourceFingerprint: "\(description)-\(daysAgo)"
    )
}

// MARK: - Recurring Detection

@Test
func insightEngine_detectsMonthlyRecurring() {
    let engine = SpendingInsightEngine()
    let transactions = [
        makeTransaction(description: "SPOTIFY", amountMinorUnits: 10900, daysAgo: 95),
        makeTransaction(description: "SPOTIFY", amountMinorUnits: 10900, daysAgo: 64),
        makeTransaction(description: "SPOTIFY", amountMinorUnits: 10900, daysAgo: 33),
        makeTransaction(description: "SPOTIFY", amountMinorUnits: 10900, daysAgo: 3)
    ]

    let insights = engine.detectRecurring(in: transactions)
    #expect(!insights.isEmpty)
    let kinds = insights.map(\.kind)
    #expect(kinds.contains(.subscriptionDetected) || kinds.contains(.recurringTransaction))
}

@Test
func insightEngine_doesNotFlagNonRecurring() {
    let engine = SpendingInsightEngine()
    let transactions = [
        makeTransaction(description: "RANDOM STORE", amountMinorUnits: 5000, daysAgo: 180),
        makeTransaction(description: "RANDOM STORE", amountMinorUnits: 9000, daysAgo: 45)
    ]
    let insights = engine.detectRecurring(in: transactions)
    #expect(insights.isEmpty)
}

@Test
func insightEngine_recurringInsightIncludesAffectedIDs() {
    let engine = SpendingInsightEngine()
    let transactions = [
        makeTransaction(description: "NETFLIX", amountMinorUnits: 64900, daysAgo: 93),
        makeTransaction(description: "NETFLIX", amountMinorUnits: 64900, daysAgo: 62),
        makeTransaction(description: "NETFLIX", amountMinorUnits: 64900, daysAgo: 31),
        makeTransaction(description: "NETFLIX", amountMinorUnits: 64900, daysAgo: 1)
    ]
    let insights = engine.detectRecurring(in: transactions)
    let combined = insights.flatMap(\.affectedTransactionIDs)
    #expect(!combined.isEmpty)
}

// MARK: - Spike Detection

@Test
func insightEngine_detectsSpendingSpike() {
    let engine = SpendingInsightEngine()
    var transactions: [Transaction] = []
    // 5 months of normal spending (~₹5,000/month = 500,000 minor units)
    for month in 1 ... 5 {
        transactions.append(makeTransaction(
            description: "GROCERY STORE", amountMinorUnits: 500_000 + Int64(month * 1000),
            daysAgo: (6 - month) * 30
        ))
    }
    // Latest month: massive spike — satisfies statistical, 20% relative, and ₹5,000 absolute guards
    transactions.append(makeTransaction(
        description: "LUXURY SHOPPING", amountMinorUnits: 4_000_000, daysAgo: 5
    ))
    transactions.append(makeTransaction(
        description: "BIG PURCHASE", amountMinorUnits: 3_000_000, daysAgo: 3
    ))

    let insights = engine.detectSpikes(in: transactions)
    let hasSpike = insights.contains { $0.kind == .spendingSpike }
    #expect(hasSpike)
}

@Test
func insightEngine_noSpikeForConsistentSpending() {
    let engine = SpendingInsightEngine()
    var transactions: [Transaction] = []
    for month in 1 ... 5 {
        transactions.append(makeTransaction(
            description: "GROCERY", amountMinorUnits: 10000,
            daysAgo: (6 - month) * 30
        ))
    }
    let insights = engine.detectSpikes(in: transactions)
    #expect(!insights.contains { $0.kind == .spendingSpike })
}

// MARK: - Unusually Large Transaction

@Test
func insightEngine_detectsUnusuallyLargeTransaction() {
    let engine = SpendingInsightEngine()
    var transactions: [Transaction] = []
    for i in 0 ..< 10 {
        transactions.append(makeTransaction(
            description: "DAILY COFFEE", amountMinorUnits: 25000, daysAgo: i * 3
        ))
    }
    // One extreme outlier
    transactions.append(makeTransaction(
        description: "MACBOOK PRO PURCHASE", amountMinorUnits: 20_000_000, daysAgo: 1
    ))

    let insights = engine.detectUnusuallyLarge(in: transactions)
    #expect(insights.contains { $0.kind == .unusuallyLargeTransaction })
}

@Test
func insightEngine_allInsightConfidencesBounded() {
    let engine = SpendingInsightEngine()
    let transactions = [
        makeTransaction(description: "SPOTIFY", amountMinorUnits: 10900, daysAgo: 90),
        makeTransaction(description: "SPOTIFY", amountMinorUnits: 10900, daysAgo: 60),
        makeTransaction(description: "SPOTIFY", amountMinorUnits: 10900, daysAgo: 30),
        makeTransaction(description: "SPOTIFY", amountMinorUnits: 10900, daysAgo: 1)
    ]
    let insights = engine.generate(for: transactions)
    for insight in insights {
        #expect(insight.confidence >= 0.0)
        #expect(insight.confidence <= 1.0)
    }
}

// MARK: - Feature Extraction

@Test
func featureExtractor_detectsPayrollIndicator() {
    let extractor = TransactionFeatureExtractor()
    let txn = makeTransaction(description: "SALARY CREDIT ACME CORP", amountMinorUnits: 500_000, daysAgo: 1)
    let features = extractor.extract(from: txn)
    #expect(features.hasPayrollIndicator)
}

@Test
func featureExtractor_detectsTransferIndicator() {
    let extractor = TransactionFeatureExtractor()
    let txn = makeTransaction(description: "NEFT TO JOHN DOE REF 12345678", amountMinorUnits: 10000, daysAgo: 1)
    let features = extractor.extract(from: txn)
    #expect(features.hasTransferIndicator)
}

@Test
func featureExtractor_detectsRefundIndicator() {
    let extractor = TransactionFeatureExtractor()
    let txn = makeTransaction(
        description: "REFUND FROM AMAZON ORDER", amountMinorUnits: 5000, daysAgo: 1, type: .credit
    )
    let features = extractor.extract(from: txn)
    #expect(features.hasRefundIndicator)
}

@Test
func featureExtractor_absoluteAmountAlwaysPositive() {
    let extractor = TransactionFeatureExtractor()
    let txn = makeTransaction(description: "REFUND", amountMinorUnits: 1000, daysAgo: 1, type: .credit)
    let features = extractor.extract(from: txn)
    #expect(features.absoluteAmountMinorUnits >= 0)
}

@Test
func featureExtractor_tokensAreNonEmpty() {
    let extractor = TransactionFeatureExtractor()
    let txn = makeTransaction(description: "STARBUCKS COFFEE", amountMinorUnits: 500, daysAgo: 1)
    let features = extractor.extract(from: txn)
    #expect(!features.tokens.isEmpty)
    #expect(features.tokens.allSatisfy { $0.count >= 2 })
}

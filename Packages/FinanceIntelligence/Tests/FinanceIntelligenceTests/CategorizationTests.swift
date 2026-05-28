import FinanceCore
@testable import FinanceIntelligence
import Foundation
import Testing

// MARK: - Test Fixture Factory

private func makeFeatures(
    description: String,
    amount: Int64 = 1000,
    isDebit: Bool = true
) -> TransactionFeatures {
    let cleaner = MerchantTextCleaner()
    let normalized = cleaner.normalizedForMatching(description)
    let tokens = normalized.components(separatedBy: CharacterSet.alphanumerics.inverted).filter { $0.count >= 2 }
    return TransactionFeatures(
        rawDescription: description,
        normalizedDescription: normalized,
        tokens: tokens,
        amountMinorUnits: isDebit ? amount : -amount,
        absoluteAmountMinorUnits: amount,
        isDebit: isDebit,
        currencyCode: "INR",
        dayOfWeek: 3,
        dayOfMonth: 15,
        month: 5,
        isWeekend: false,
        hasOnlineIndicator: normalized.contains("online"),
        hasRecurringIndicator: normalized.contains("subscription"),
        hasTransferIndicator: normalized.contains("neft") || normalized.contains("upi"),
        hasPayrollIndicator: normalized.contains("salary") || normalized.contains("payroll"),
        hasRefundIndicator: normalized.contains("refund"),
        institutionHint: nil,
        ledgerKindHint: nil
    )
}

// MARK: - RuleBasedCategorizer

@Test
func categorizer_classifiesSalaryAsIncome() {
    let categorizer = RuleBasedCategorizer()
    let features = makeFeatures(description: "SALARY CREDIT JUNE 2026", isDebit: false)
    let prediction = categorizer.categorize(features)
    #expect(prediction.categoryId == "income")
    #expect(prediction.confidence > 0.8)
}

@Test
func categorizer_classifiesPayrollAsIncome() {
    let categorizer = RuleBasedCategorizer()
    let features = makeFeatures(description: "PAYROLL DEPOSIT ACME CORP", isDebit: false)
    let prediction = categorizer.categorize(features)
    #expect(prediction.categoryId == "income")
}

@Test
func categorizer_classifiesUberAsTransportation() {
    let categorizer = RuleBasedCategorizer()
    let features = makeFeatures(description: "UBER TRIP HELP.UBER.COM")
    let prediction = categorizer.categorize(features)
    #expect(prediction.categoryId == "transportation")
}

@Test
func categorizer_classifiesStarbucksAsDining() {
    let categorizer = RuleBasedCategorizer()
    let features = makeFeatures(description: "STARBUCKS COFFEE 12345")
    let prediction = categorizer.categorize(features)
    #expect(prediction.categoryId == "dining")
}

@Test
func categorizer_classifiesSpotifyAsSubscription() {
    let categorizer = RuleBasedCategorizer()
    let features = makeFeatures(description: "SPOTIFY AB STOCKHOLM")
    let prediction = categorizer.categorize(features)
    #expect(prediction.categoryId == "subscriptions")
}

@Test
func categorizer_classifiesNetflixAsSubscription() {
    let categorizer = RuleBasedCategorizer()
    let features = makeFeatures(description: "NETFLIX.COM")
    let prediction = categorizer.categorize(features)
    #expect(prediction.categoryId == "subscriptions")
}

@Test
func categorizer_classifiesATMWithdrawal() {
    let categorizer = RuleBasedCategorizer()
    let features = makeFeatures(description: "ATM WITHDRAWAL HDFC BANK 12345")
    let prediction = categorizer.categorize(features)
    #expect(prediction.categoryId == "atm")
}

@Test
func categorizer_classifiesNEFTAsTransfer() {
    let categorizer = RuleBasedCategorizer()
    let features = makeFeatures(description: "NEFT TO JOHN DOE REF 12345678")
    let prediction = categorizer.categorize(features)
    #expect(prediction.categoryId == "transfers")
}

@Test
func categorizer_refundClassifiedAsIncome() {
    let categorizer = RuleBasedCategorizer()
    let features = makeFeatures(description: "REFUND FROM AMAZON", isDebit: false)
    let prediction = categorizer.categorize(features)
    #expect(prediction.categoryId == "income")
}

@Test
func categorizer_unknownDescriptionFallsToUncategorized() {
    let categorizer = RuleBasedCategorizer()
    let features = makeFeatures(description: "XYZ CORP ABCDEF")
    let prediction = categorizer.categorize(features)
    #expect(prediction.categoryId == "uncategorized")
    #expect(prediction.confidence < 0.5)
}

@Test
func categorizer_predictionIncludesModelVersion() {
    let categorizer = RuleBasedCategorizer()
    let features = makeFeatures(description: "STARBUCKS")
    let prediction = categorizer.categorize(features)
    #expect(!prediction.modelVersion.isEmpty)
    #expect(!prediction.taxonomyVersion.isEmpty)
}

@Test
func categorizer_confidenceAlwaysBetweenZeroAndOne() {
    let categorizer = RuleBasedCategorizer()
    let descriptions = [
        "SALARY", "UBER TRIP", "NETFLIX", "ATM WITHDRAWAL",
        "NEFT TRANSFER", "AMAZON PURCHASE", "SOME RANDOM THING"
    ]
    for desc in descriptions {
        let prediction = categorizer.categorize(makeFeatures(description: desc))
        #expect(prediction.confidence >= 0.0, "Confidence below 0 for: \(desc)")
        #expect(prediction.confidence <= 1.0, "Confidence above 1 for: \(desc)")
    }
}

// MARK: - UserCorrectionStore

@Test
func correctionStore_recordAndRetrieve() async throws {
    let url = FileManager.default.temporaryDirectory
        .appendingPathComponent("test-corrections-\(UUID().uuidString).json")
    let store = UserCorrectionStore(storageURL: url)

    let txnId = UUID()
    try await store.record(CorrectionInput(
        transactionId: txnId,
        originalCategory: "uncategorized",
        correctedCategory: "groceries",
        originalMerchant: "DMART",
        correctedMerchant: "D-Mart",
        originalConfidence: 0.3,
        modelVersion: "rules-1.0.0"
    ))

    let correction = await store.correction(for: txnId)
    #expect(correction?.correctedCategory == "groceries")
    #expect(correction?.correctedMerchant == "D-Mart")
    #expect(correction?.isTrainingEligible == true)

    try? FileManager.default.removeItem(at: url)
}

@Test
func correctionStore_returnsNilForUnknownTransaction() async {
    let url = FileManager.default.temporaryDirectory
        .appendingPathComponent("test-corrections-\(UUID().uuidString).json")
    let store = UserCorrectionStore(storageURL: url)
    let result = await store.correction(for: UUID())
    #expect(result == nil)
}

@Test
func correctionStore_exportTrainingEligible() async throws {
    let url = FileManager.default.temporaryDirectory
        .appendingPathComponent("test-corrections-\(UUID().uuidString).json")
    let store = UserCorrectionStore(storageURL: url)

    for _ in 0 ..< 3 {
        let input = CorrectionInput(
            transactionId: UUID(),
            originalCategory: "uncategorized",
            correctedCategory: "dining",
            originalMerchant: nil,
            correctedMerchant: nil,
            originalConfidence: nil,
            modelVersion: nil
        )
        try await store.record(input)
    }

    let eligible = await store.exportTrainingEligible()
    #expect(eligible.count == 3)
    for correction in eligible {
        #expect(correction.isTrainingEligible)
    }

    try? FileManager.default.removeItem(at: url)
}

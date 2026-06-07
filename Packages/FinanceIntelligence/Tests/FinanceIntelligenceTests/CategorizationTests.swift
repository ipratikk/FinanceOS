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
        hasCreditCardPaymentIndicator: {
            let lower = description.lowercased()
            return lower.contains("bbps") ||
                (!isDebit && lower.contains("payment received")) ||
                lower.contains("aebc") ||
                lower.contains("cred.club") ||
                lower.contains("upi-american express")
        }(),
        institutionHint: nil,
        ledgerKindHint: nil
    )
}

// MARK: - hasCreditCardPaymentIndicator

@Test func ccPayment_bbps_isDetected() {
    let f = makeFeatures(description: "BBPS Payment received", isDebit: false)
    #expect(f.hasCreditCardPaymentIndicator == true)
}

@Test func ccPayment_amexUPI_isDetected() {
    let f = makeFeatures(description: "UPI-AMERICAN EXPRESS-AEBC373008620701005@SC-SCBL0036051")
    #expect(f.hasCreditCardPaymentIndicator == true)
}

@Test func ccPayment_credClub_isDetected() {
    let f = makeFeatures(description: "UPI-CRED CLUB-CRED.CLUB@AXISB-UTIB0000114-PAYMENT ON CRED")
    #expect(f.hasCreditCardPaymentIndicator == true)
}

@Test func ccPayment_paymentReceived_credit_isDetected() {
    let f = makeFeatures(description: "PAYMENT RECEIVED. THANK YOU", isDebit: false)
    #expect(f.hasCreditCardPaymentIndicator == true)
}

@Test func ccPayment_salary_isNotDetected() {
    let f = makeFeatures(description: "SALARY CREDIT JUNE 2026", isDebit: false)
    #expect(f.hasCreditCardPaymentIndicator == false)
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

// MARK: - Indian banking rules

@Test func rule_bbps_isTransfers() {
    let f = makeFeatures(description: "BBPS Payment received", isDebit: false)
    let pred = RuleBasedCategorizer().categorize(f)
    #expect(pred.categoryId == "transfers")
    #expect(pred.subcategoryId == "transfers.creditCardPayment")
}

@Test func rule_paymentReceived_credit_isTransfers() {
    let f = makeFeatures(description: "PAYMENT RECEIVED. THANK YOU", isDebit: false)
    let pred = RuleBasedCategorizer().categorize(f)
    #expect(pred.categoryId == "transfers")
}

@Test func rule_gst_isFees() {
    let f = makeFeatures(description: "GST/IGST@18%")
    let pred = RuleBasedCategorizer().categorize(f)
    #expect(pred.categoryId == "fees")
}

@Test func rule_financeCharges_isFeesInterest() {
    let f = makeFeatures(description: "FINANCE CHARGES")
    let pred = RuleBasedCategorizer().categorize(f)
    #expect(pred.categoryId == "fees")
    #expect(pred.subcategoryId == "fees.interest")
}

@Test func rule_interestPaid_isIncomeInterest() {
    let f = makeFeatures(description: "INTEREST PAID TILL 31-MAR-2026", isDebit: false)
    let pred = RuleBasedCategorizer().categorize(f)
    #expect(pred.categoryId == "income")
    #expect(pred.subcategoryId == "income.interest")
}

@Test func rule_installmentPrincipal_isFeesInterest() {
    let f = makeFeatures(description: "INSTALLMENT PRINCIPAL AMOUNT")
    let pred = RuleBasedCategorizer().categorize(f)
    #expect(pred.categoryId == "fees")
}

@Test func rule_iccl_isInvestments() {
    let f = makeFeatures(description: "ACH D- INDIAN CLEARING CORP-00001I15H47A36-SIP")
    let pred = RuleBasedCategorizer().categorize(f)
    #expect(pred.categoryId == "investments")
}

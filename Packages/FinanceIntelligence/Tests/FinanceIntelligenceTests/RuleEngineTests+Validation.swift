@testable import FinanceIntelligence
import Testing




// MARK: - Confidence Bounds

@Test
func ruleEngine_confidenceAlwaysBetweenZeroAndOne() {
    let descriptions = [
        "SALARY CREDIT JUNE 2026",
        "UPI-AMERICAN EXPRESS-AEBC373",
        "SIP GROWW MONTHLY",
        "NETFLIX SUBSCRIPTION",
        "ATM WITHDRAWAL HDFC",
        "SWIGGY ORDER 999",
        "SOME COMPLETELY UNKNOWN MERCHANT XYZ"
    ]
    let eng = makeRuleEngine()
    for desc in descriptions {
        let result = eng.evaluate(makeFeatures(description: desc, isDebit: false))
        #expect(result.intentPrediction.confidence >= 0.0, "Confidence below 0 for: \(desc)")
        #expect(result.intentPrediction.confidence <= 1.0, "Confidence above 1 for: \(desc)")
        result.categoryPrediction.map { pred in
            #expect(pred.confidence >= 0.0, "Category confidence below 0 for: \(desc)")
            #expect(pred.confidence <= 1.0, "Category confidence above 1 for: \(desc)")
        }
    }
}

// MARK: - Unknown / Catch-all

@Test
func ruleEngine_unknown_randomMerchant() {
    let result = makeRuleEngine().evaluate(makeFeatures(description: "XYZ CORP ABCDEF RANDOM 9999"))
    #expect(result.intentPrediction.intent == .unknown)
    #expect(result.intentPrediction.confidence < 0.5)
}

@Test
func ruleEngine_catchAll_creditFallback() {
    let result = makeRuleEngine().evaluate(
        makeFeatures(
            description: "UNKNOWN CREDIT ENTRY 777",
            isDebit: false,
            hasPayrollIndicator: false,
            hasRefundIndicator: false
        )
    )
    #expect(result.intentPrediction.intent == .income)
    #expect(result.categoryPrediction?.categoryId == "income")
}

// MARK: - Rule Priority Ordering

@Test
func ruleEngine_salary_takesOverCreditCatchall() {
    let result = makeRuleEngine().evaluate(makeFeatures(description: "SALARY CREDIT WIPRO", isDebit: false))
    #expect(result.intentPrediction.intent == .salary)
    #expect(result.matchedRuleId != "catchall.credit")
}

@Test
func ruleEngine_refund_takesOverTransfer() {
    let result = makeRuleEngine().evaluate(
        makeFeatures(
            description: "REFUND NEFT AMAZON RETURN",
            hasRefundIndicator: true,
            hasTransferIndicator: true
        )
    )
    #expect(result.intentPrediction.intent == .refund)
}

@Test
func ruleEngine_sip_takesOverTransfer() {
    let result = makeRuleEngine().evaluate(
        makeFeatures(description: "SIP NACH DEBIT AXIS MF", hasTransferIndicator: true)
    )
    #expect(result.intentPrediction.intent == .mutualFundSIP)
}

// MARK: - Structural intent coverage (kNN-delegated intents excluded)

@Test
func ruleEngine_structuralIntentsCovered_inBuiltInRules() {
    // Intents handled by kNN/ML (intentionally excluded from BuiltInRules.all):
    // food, groceries, shopping, subscription, travel, healthcare, utilityBill, investment
    let builtInIntents = Set(BuiltInRules.all.map(\.outcome.intent)).filter { $0 != .unknown }
    let allIntents = Set(TransactionIntent.allCases.filter { $0 != .unknown })
    let knnDelegatedIntents: Set<TransactionIntent> = [
        .food, .groceries, .shopping, .subscription, .travel, .healthcare, .utilityBill, .investment
    ]
    let expectedStructuralIntents = allIntents.subtracting(knnDelegatedIntents)
    #expect(builtInIntents == expectedStructuralIntents,
            "BuiltInRules coverage mismatch. Expected: \(expectedStructuralIntents.map(\.rawValue).sorted()), Got: \(builtInIntents.map(\.rawValue).sorted())")
}

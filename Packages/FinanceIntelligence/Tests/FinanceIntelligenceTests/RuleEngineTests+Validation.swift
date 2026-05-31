@testable import FinanceIntelligence
import Testing

// MARK: - Travel

@Test
func ruleEngine_travel_uber() {
    let result = makeRuleEngine().evaluate(makeFeatures(description: "UBER TRIP HELP.UBER.COM"))
    #expect(result.intentPrediction.intent == .travel)
    #expect(result.categoryPrediction?.categoryId == "transportation")
}

@Test
func ruleEngine_travel_ola() {
    let result = makeRuleEngine().evaluate(makeFeatures(description: "OLA CABS PAYMENT 9876"))
    #expect(result.intentPrediction.intent == .travel)
}

@Test
func ruleEngine_travel_irctc() {
    let result = makeRuleEngine().evaluate(makeFeatures(description: "IRCTC TICKET BOOKING"))
    #expect(result.intentPrediction.intent == .travel)
}

@Test
func ruleEngine_travel_makemytrip() {
    let result = makeRuleEngine().evaluate(makeFeatures(description: "MAKEMYTRIP FLIGHT BOOKING"))
    #expect(result.intentPrediction.intent == .travel)
}

@Test
func ruleEngine_travel_indigo() {
    let result = makeRuleEngine().evaluate(makeFeatures(description: "INDIGO AIRLINES TICKET"))
    #expect(result.intentPrediction.intent == .travel)
}

// MARK: - Healthcare

@Test
func ruleEngine_healthcare_apollo() {
    let result = makeRuleEngine().evaluate(makeFeatures(description: "APOLLO HOSPITAL CONSULTATION"))
    #expect(result.intentPrediction.intent == .healthcare)
    #expect(result.categoryPrediction?.categoryId == "healthcare")
}

@Test
func ruleEngine_healthcare_medplus() {
    let result = makeRuleEngine().evaluate(makeFeatures(description: "MEDPLUS PHARMACY ORDER"))
    #expect(result.intentPrediction.intent == .healthcare)
}

@Test
func ruleEngine_healthcare_netmeds() {
    let result = makeRuleEngine().evaluate(makeFeatures(description: "NETMEDS ONLINE PHARMACY"))
    #expect(result.intentPrediction.intent == .healthcare)
}

@Test
func ruleEngine_healthcare_medical() {
    let result = makeRuleEngine().evaluate(makeFeatures(description: "MEDICAL BILL CLINIC PAYMENT"))
    #expect(result.intentPrediction.intent == .healthcare)
}

// MARK: - Investment (Stocks)

@Test
func ruleEngine_investment_zerodha() {
    let result = makeRuleEngine().evaluate(makeFeatures(description: "ZERODHA STOCK PURCHASE NSE"))
    #expect(result.intentPrediction.intent == .investment)
    #expect(result.categoryPrediction?.categoryId == "transfers")
}

@Test
func ruleEngine_investment_demat() {
    let result = makeRuleEngine().evaluate(makeFeatures(description: "DEMAT ACCOUNT SHARES PURCHASE"))
    #expect(result.intentPrediction.intent == .investment)
}

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

// MARK: - Intent Count (all intents covered)

@Test
func ruleEngine_allIntentsCovered_inBuiltInRules() {
    let allIntents = TransactionIntent.allCases.filter { $0 != .unknown }
    let ruleOutcomeIntents = Set(BuiltInRules.all.map(\.outcome.intent))
    for intent in allIntents {
        #expect(ruleOutcomeIntents.contains(intent), "No rule covers intent: \(intent.rawValue)")
    }
}

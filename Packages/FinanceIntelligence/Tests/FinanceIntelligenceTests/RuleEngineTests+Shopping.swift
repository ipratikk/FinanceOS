@testable import FinanceIntelligence
import Testing

// MARK: - Groceries

@Test
func ruleEngine_groceries_bigbasket() {
    let result = makeRuleEngine().evaluate(makeFeatures(description: "BIGBASKET ORDER 45678"))
    #expect(result.intentPrediction.intent == .groceries)
    #expect(result.categoryPrediction?.categoryId == "groceries")
}

@Test
func ruleEngine_groceries_zepto() {
    let result = makeRuleEngine().evaluate(makeFeatures(description: "ZEPTO MARKETPLACE ORDER"))
    #expect(result.intentPrediction.intent == .groceries)
}

@Test
func ruleEngine_groceries_dmart() {
    let result = makeRuleEngine().evaluate(makeFeatures(description: "DMART SUPERMARKET HEBBAL"))
    #expect(result.intentPrediction.intent == .groceries)
}

@Test
func ruleEngine_groceries_blinkit() {
    let result = makeRuleEngine().evaluate(makeFeatures(description: "BLINKIT QUICK DELIVERY"))
    #expect(result.intentPrediction.intent == .groceries)
}

// MARK: - Shopping

@Test
func ruleEngine_shopping_amazon() {
    let result = makeRuleEngine().evaluate(makeFeatures(description: "AMZN MKTP US PURCHASE"))
    #expect(result.intentPrediction.intent == .shopping)
    #expect(result.categoryPrediction?.categoryId == "shopping")
}

@Test
func ruleEngine_shopping_flipkart() {
    let result = makeRuleEngine().evaluate(makeFeatures(description: "FLIPKART INTERNET PAYMENT"))
    #expect(result.intentPrediction.intent == .shopping)
}

@Test
func ruleEngine_shopping_myntra() {
    let result = makeRuleEngine().evaluate(makeFeatures(description: "MYNTRA FASHION PURCHASE"))
    #expect(result.intentPrediction.intent == .shopping)
}

@Test
func ruleEngine_shopping_meesho() {
    let result = makeRuleEngine().evaluate(makeFeatures(description: "MEESHO ORDER PAYMENT"))
    #expect(result.intentPrediction.intent == .shopping)
}

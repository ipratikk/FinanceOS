@testable import FinanceIntelligence
import Foundation
import Testing

// MARK: - Fixture Factory

private func makeFeatures(
    description: String,
    isDebit: Bool = true,
    amount: Int64 = 100_000,
    hasPayrollIndicator: Bool? = nil,
    hasRefundIndicator: Bool? = nil,
    hasTransferIndicator: Bool? = nil,
    hasRecurringIndicator: Bool? = nil
) -> TransactionFeatures {
    let cleaner = MerchantTextCleaner()
    let normalized = cleaner.normalizedForMatching(description)
    let tokens = normalized
        .components(separatedBy: CharacterSet.alphanumerics.inverted)
        .filter { $0.count >= 2 }
    // Derive indicators from description text unless an override is provided.
    let payroll = hasPayrollIndicator
        ?? (normalized.contains("salary") || normalized.contains("payroll")
            || normalized.contains("paycheck") || normalized.contains("wages")
            || normalized.contains("stipend"))
    let refund = hasRefundIndicator
        ?? (normalized.contains("refund") || normalized.contains("reversal")
            || normalized.contains("chargeback") || normalized.contains("cashback"))
    let transfer = hasTransferIndicator
        ?? (normalized.contains("neft") || normalized.contains("imps")
            || normalized.contains("rtgs") || normalized.contains("upi"))
    let recurring = hasRecurringIndicator
        ?? (normalized.contains("subscription") || normalized.contains("emi"))
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
        hasOnlineIndicator: normalized.contains("online") || normalized.contains(".com"),
        hasRecurringIndicator: recurring,
        hasTransferIndicator: transfer,
        hasPayrollIndicator: payroll,
        hasRefundIndicator: refund,
        institutionHint: nil,
        ledgerKindHint: nil
    )
}

private func engine() -> RuleEngine { RuleEngine() }

// MARK: - Salary

@Test func ruleEngine_salaryCredit_indicatorAndCredit() {
    let result = engine().evaluate(makeFeatures(description: "SALARY CREDIT JUNE 2026", isDebit: false))
    #expect(result.intentPrediction.intent == .salary)
    #expect(result.intentPrediction.confidence >= 0.93)
    #expect(result.categoryPrediction?.categoryId == "income")
    #expect(result.matchedRuleId == "income.salary")
}

@Test func ruleEngine_salary_hdfc() {
    let result = engine().evaluate(makeFeatures(description: "SALARY HDFC BANK JUNE", isDebit: false))
    #expect(result.intentPrediction.intent == .salary)
    #expect(result.categoryPrediction?.categoryId == "income")
}

@Test func ruleEngine_salary_payroll() {
    let result = engine().evaluate(makeFeatures(description: "PAYROLL DEPOSIT TATA CONSULTANCY", isDebit: false))
    #expect(result.intentPrediction.intent == .salary)
    #expect(result.intentPrediction.confidence >= 0.90)
}

@Test func ruleEngine_salary_wages() {
    let result = engine().evaluate(makeFeatures(description: "WAGES PAYMENT INFOSYS", isDebit: false))
    #expect(result.intentPrediction.intent == .salary)
}

@Test func ruleEngine_salary_stipend() {
    let result = engine().evaluate(makeFeatures(description: "STIPEND CREDIT IIT DELHI", isDebit: false))
    #expect(result.intentPrediction.intent == .salary)
}

// MARK: - Refund

@Test func ruleEngine_refund_amazon() {
    let result = engine().evaluate(makeFeatures(description: "REFUND FROM AMAZON ORDER 12345", isDebit: false))
    #expect(result.intentPrediction.intent == .refund)
    #expect(result.intentPrediction.confidence >= 0.88)
    #expect(result.categoryPrediction?.categoryId == "income")
}

@Test func ruleEngine_refund_reversal() {
    let result = engine().evaluate(makeFeatures(description: "REVERSAL ZOMATO TXN 98765"))
    #expect(result.intentPrediction.intent == .refund)
}

@Test func ruleEngine_refund_flipkart() {
    let result = engine().evaluate(makeFeatures(description: "REFUND FLIPKART ELECTRONICS"))
    #expect(result.intentPrediction.intent == .refund)
}

@Test func ruleEngine_refund_chargeback() {
    let result = engine().evaluate(makeFeatures(description: "CHARGEBACK PROCESSED VISA"))
    #expect(result.intentPrediction.intent == .refund)
}

@Test func ruleEngine_refund_swiggy() {
    let result = engine().evaluate(makeFeatures(description: "REVERSAL SWIGGY ORDER CANCELLED"))
    #expect(result.intentPrediction.intent == .refund)
}

// MARK: - Cashback

@Test func ruleEngine_cashback_reward() {
    let result = engine().evaluate(
        makeFeatures(description: "CASHBACK RECEIVED HDFC", isDebit: false,
                     hasRefundIndicator: false)
    )
    #expect(result.intentPrediction.intent == .cashback)
}

@Test func ruleEngine_cashback_rewardCredit() {
    let result = engine().evaluate(
        makeFeatures(description: "REWARD CREDIT AMEX CARD", isDebit: false,
                     hasRefundIndicator: false)
    )
    #expect(result.intentPrediction.intent == .cashback)
}

// MARK: - Credit Card Payment

@Test func ruleEngine_creditCard_amex() {
    let result = engine().evaluate(
        makeFeatures(description: "UPI-AMERICAN EXPRESS-AEBC373008620701005")
    )
    #expect(result.intentPrediction.intent == .creditCardPayment)
    #expect(result.intentPrediction.confidence >= 0.90)
    #expect(result.categoryPrediction?.categoryId == "fees")
}

@Test func ruleEngine_creditCard_amexShort() {
    let result = engine().evaluate(makeFeatures(description: "AMEX PAYMENT DUE"))
    #expect(result.intentPrediction.intent == .creditCardPayment)
}

@Test func ruleEngine_creditCard_hdfcCC() {
    let result = engine().evaluate(makeFeatures(description: "HDFC CC PAYMENT AUTOPAY"))
    #expect(result.intentPrediction.intent == .creditCardPayment)
}

@Test func ruleEngine_creditCard_sbiCard() {
    let result = engine().evaluate(makeFeatures(description: "SBI CARD PAYMENT BILL"))
    #expect(result.intentPrediction.intent == .creditCardPayment)
}

@Test func ruleEngine_creditCard_cardPayment() {
    let result = engine().evaluate(makeFeatures(description: "CREDIT CARD PAYMENT BILLDESK"))
    #expect(result.intentPrediction.intent == .creditCardPayment)
}

// MARK: - Mutual Fund SIP

@Test func ruleEngine_sip_groww() {
    let result = engine().evaluate(makeFeatures(description: "SIP DEBIT GROWW MUTUAL FUND"))
    #expect(result.intentPrediction.intent == .mutualFundSIP)
    #expect(result.intentPrediction.confidence >= 0.90)
    #expect(result.categoryPrediction?.categoryId == "transfers")
}

@Test func ruleEngine_sip_kuvera() {
    let result = engine().evaluate(makeFeatures(description: "KUVERA SIP NIFTY 50"))
    #expect(result.intentPrediction.intent == .mutualFundSIP)
}

@Test func ruleEngine_sip_nach() {
    let result = engine().evaluate(makeFeatures(description: "NACH DEBIT SBI MF"))
    #expect(result.intentPrediction.intent == .mutualFundSIP)
}

@Test func ruleEngine_sip_miraeasset() {
    let result = engine().evaluate(makeFeatures(description: "MIRAE ASSET SIP MONTHLY"))
    #expect(result.intentPrediction.intent == .mutualFundSIP)
}

@Test func ruleEngine_sip_nippon() {
    let result = engine().evaluate(makeFeatures(description: "NIPPON INDIA MUTUAL FUND SIP"))
    #expect(result.intentPrediction.intent == .mutualFundSIP)
}

// MARK: - Insurance

@Test func ruleEngine_insurance_lic() {
    let result = engine().evaluate(makeFeatures(description: "LIC PREMIUM PAYMENT"))
    #expect(result.intentPrediction.intent == .insurance)
    #expect(result.intentPrediction.confidence >= 0.90)
    #expect(result.categoryPrediction?.categoryId == "insurance")
}

@Test func ruleEngine_insurance_maxLife() {
    let result = engine().evaluate(makeFeatures(description: "MAX LIFE INSURANCE PREMIUM"))
    #expect(result.intentPrediction.intent == .insurance)
}

@Test func ruleEngine_insurance_starHealth() {
    let result = engine().evaluate(makeFeatures(description: "STAR HEALTH POLICY RENEWAL"))
    #expect(result.intentPrediction.intent == .insurance)
}

@Test func ruleEngine_insurance_hdfcLife() {
    let result = engine().evaluate(makeFeatures(description: "HDFC LIFE INSURANCE MONTHLY"))
    #expect(result.intentPrediction.intent == .insurance)
}

@Test func ruleEngine_insurance_bajajAllianz() {
    let result = engine().evaluate(makeFeatures(description: "BAJAJ ALLIANZ INSURANCE DEBIT"))
    #expect(result.intentPrediction.intent == .insurance)
}

// MARK: - Subscription

@Test func ruleEngine_subscription_netflix() {
    let result = engine().evaluate(makeFeatures(description: "NETFLIX SUBSCRIPTION MONTHLY"))
    #expect(result.intentPrediction.intent == .subscription)
    #expect(result.intentPrediction.confidence >= 0.88)
    #expect(result.categoryPrediction?.categoryId == "subscriptions")
}

@Test func ruleEngine_subscription_spotify() {
    let result = engine().evaluate(makeFeatures(description: "SPOTIFY AB STOCKHOLM"))
    #expect(result.intentPrediction.intent == .subscription)
}

@Test func ruleEngine_subscription_amazonPrime() {
    let result = engine().evaluate(makeFeatures(description: "AMAZON PRIME MEMBERSHIP"))
    #expect(result.intentPrediction.intent == .subscription)
}

@Test func ruleEngine_subscription_hotstar() {
    let result = engine().evaluate(makeFeatures(description: "DISNEY HOTSTAR ANNUAL PLAN"))
    #expect(result.intentPrediction.intent == .subscription)
}

@Test func ruleEngine_subscription_linkedinPremium() {
    let result = engine().evaluate(makeFeatures(description: "LINKEDIN PREMIUM MONTHLY"))
    #expect(result.intentPrediction.intent == .subscription)
}

// MARK: - Cash Withdrawal

@Test func ruleEngine_atm_withdrawal() {
    let result = engine().evaluate(makeFeatures(description: "ATM WITHDRAWAL HDFC BANK"))
    #expect(result.intentPrediction.intent == .cashWithdrawal)
    #expect(result.intentPrediction.confidence >= 0.90)
    #expect(result.categoryPrediction?.categoryId == "atm")
}

@Test func ruleEngine_atm_cashWithdrawal() {
    let result = engine().evaluate(makeFeatures(description: "CASH WITHDRAWAL SBI ATM PUNE"))
    #expect(result.intentPrediction.intent == .cashWithdrawal)
}

@Test func ruleEngine_atm_icici() {
    let result = engine().evaluate(makeFeatures(description: "ATM CASH ICICI BANK 1234"))
    #expect(result.intentPrediction.intent == .cashWithdrawal)
}

// MARK: - Rent

@Test func ruleEngine_rent_generic() {
    let result = engine().evaluate(
        makeFeatures(description: "RENT PAYMENT RITIK GUPTA", hasTransferIndicator: false)
    )
    #expect(result.intentPrediction.intent == .rent)
    #expect(result.categoryPrediction?.categoryId == "housing")
}

@Test func ruleEngine_rent_houseRent() {
    let result = engine().evaluate(
        makeFeatures(description: "HOUSE RENT OCTOBER 2026", hasTransferIndicator: false)
    )
    #expect(result.intentPrediction.intent == .rent)
}

@Test func ruleEngine_rent_flatRent() {
    let result = engine().evaluate(
        makeFeatures(description: "FLAT RENT BANGALORE SECTOR 5", hasTransferIndicator: false)
    )
    #expect(result.intentPrediction.intent == .rent)
}

// MARK: - Loan Payment

@Test func ruleEngine_loan_emi() {
    let result = engine().evaluate(makeFeatures(description: "LOAN EMI HDFC BANK"))
    #expect(result.intentPrediction.intent == .loanPayment)
    #expect(result.categoryPrediction?.categoryId == "fees")
}

@Test func ruleEngine_loan_homeLoan() {
    let result = engine().evaluate(makeFeatures(description: "HOME LOAN EMI PAYMENT SBI"))
    #expect(result.intentPrediction.intent == .loanPayment)
}

@Test func ruleEngine_loan_bajaj() {
    let result = engine().evaluate(makeFeatures(description: "BAJAJ FINANCE EMI DEBIT"))
    #expect(result.intentPrediction.intent == .loanPayment)
}

// MARK: - Interest Payment

@Test func ruleEngine_interest_charge() {
    let result = engine().evaluate(makeFeatures(description: "INTEREST CHARGE CREDIT CARD OCT"))
    #expect(result.intentPrediction.intent == .interestPayment)
}

@Test func ruleEngine_interest_finance_charge() {
    let result = engine().evaluate(makeFeatures(description: "FINANCE CHARGE APPLIED AMEX"))
    #expect(result.intentPrediction.intent == .interestPayment)
}

// MARK: - Transfer

@Test func ruleEngine_transfer_neft() {
    let result = engine().evaluate(makeFeatures(description: "NEFT TO SEEMA GOEL REF 8888"))
    #expect(result.intentPrediction.intent == .transfer)
    #expect(result.categoryPrediction?.categoryId == "transfers")
}

@Test func ruleEngine_transfer_imps() {
    let result = engine().evaluate(makeFeatures(description: "IMPS AMAN PANDEY 5000"))
    #expect(result.intentPrediction.intent == .transfer)
}

@Test func ruleEngine_transfer_upi() {
    let result = engine().evaluate(makeFeatures(description: "UPI-AMAN PANDEY-AMAN@UPI-REF123"))
    #expect(result.intentPrediction.intent == .transfer)
}

// MARK: - Utility Bill

@Test func ruleEngine_utility_electricity() {
    let result = engine().evaluate(makeFeatures(description: "BESCOM ELECTRICITY BILL OCT"))
    #expect(result.intentPrediction.intent == .utilityBill)
    #expect(result.categoryPrediction?.categoryId == "utilities")
}

@Test func ruleEngine_utility_airtel() {
    let result = engine().evaluate(makeFeatures(description: "AIRTEL POSTPAID BILL PAYMENT"))
    #expect(result.intentPrediction.intent == .utilityBill)
}

@Test func ruleEngine_utility_gas() {
    let result = engine().evaluate(makeFeatures(description: "MAHANAGAR GAS MONTHLY"))
    #expect(result.intentPrediction.intent == .utilityBill)
}

@Test func ruleEngine_utility_internet() {
    let result = engine().evaluate(makeFeatures(description: "BROADBAND INTERNET BILL ACT"))
    #expect(result.intentPrediction.intent == .utilityBill)
}

// MARK: - Food & Dining

@Test func ruleEngine_food_swiggy() {
    let result = engine().evaluate(makeFeatures(description: "SWIGGY FOOD ORDER 12345"))
    #expect(result.intentPrediction.intent == .food)
    #expect(result.categoryPrediction?.categoryId == "dining")
}

@Test func ruleEngine_food_zomato() {
    let result = engine().evaluate(makeFeatures(description: "ZOMATO DELIVERY FEE"))
    #expect(result.intentPrediction.intent == .food)
}

@Test func ruleEngine_food_dominos() {
    let result = engine().evaluate(makeFeatures(description: "DOMINOS PIZZA BANGALORE"))
    #expect(result.intentPrediction.intent == .food)
}

@Test func ruleEngine_food_restaurant() {
    let result = engine().evaluate(makeFeatures(description: "RESTAURANT PAYMENT INDIRANAGAR"))
    #expect(result.intentPrediction.intent == .food)
}

// MARK: - Groceries

@Test func ruleEngine_groceries_bigbasket() {
    let result = engine().evaluate(makeFeatures(description: "BIGBASKET ORDER 45678"))
    #expect(result.intentPrediction.intent == .groceries)
    #expect(result.categoryPrediction?.categoryId == "groceries")
}

@Test func ruleEngine_groceries_zepto() {
    let result = engine().evaluate(makeFeatures(description: "ZEPTO MARKETPLACE ORDER"))
    #expect(result.intentPrediction.intent == .groceries)
}

@Test func ruleEngine_groceries_dmart() {
    let result = engine().evaluate(makeFeatures(description: "DMART SUPERMARKET HEBBAL"))
    #expect(result.intentPrediction.intent == .groceries)
}

@Test func ruleEngine_groceries_blinkit() {
    let result = engine().evaluate(makeFeatures(description: "BLINKIT QUICK DELIVERY"))
    #expect(result.intentPrediction.intent == .groceries)
}

// MARK: - Shopping

@Test func ruleEngine_shopping_amazon() {
    let result = engine().evaluate(makeFeatures(description: "AMZN MKTP US PURCHASE"))
    #expect(result.intentPrediction.intent == .shopping)
    #expect(result.categoryPrediction?.categoryId == "shopping")
}

@Test func ruleEngine_shopping_flipkart() {
    let result = engine().evaluate(makeFeatures(description: "FLIPKART INTERNET PAYMENT"))
    #expect(result.intentPrediction.intent == .shopping)
}

@Test func ruleEngine_shopping_myntra() {
    let result = engine().evaluate(makeFeatures(description: "MYNTRA FASHION PURCHASE"))
    #expect(result.intentPrediction.intent == .shopping)
}

@Test func ruleEngine_shopping_meesho() {
    let result = engine().evaluate(makeFeatures(description: "MEESHO ORDER PAYMENT"))
    #expect(result.intentPrediction.intent == .shopping)
}

// MARK: - Travel

@Test func ruleEngine_travel_uber() {
    let result = engine().evaluate(makeFeatures(description: "UBER TRIP HELP.UBER.COM"))
    #expect(result.intentPrediction.intent == .travel)
    #expect(result.categoryPrediction?.categoryId == "transportation")
}

@Test func ruleEngine_travel_ola() {
    let result = engine().evaluate(makeFeatures(description: "OLA CABS PAYMENT 9876"))
    #expect(result.intentPrediction.intent == .travel)
}

@Test func ruleEngine_travel_irctc() {
    let result = engine().evaluate(makeFeatures(description: "IRCTC TICKET BOOKING"))
    #expect(result.intentPrediction.intent == .travel)
}

@Test func ruleEngine_travel_makemytrip() {
    let result = engine().evaluate(makeFeatures(description: "MAKEMYTRIP FLIGHT BOOKING"))
    #expect(result.intentPrediction.intent == .travel)
}

@Test func ruleEngine_travel_indigo() {
    let result = engine().evaluate(makeFeatures(description: "INDIGO AIRLINES TICKET"))
    #expect(result.intentPrediction.intent == .travel)
}

// MARK: - Healthcare

@Test func ruleEngine_healthcare_apollo() {
    let result = engine().evaluate(makeFeatures(description: "APOLLO HOSPITAL CONSULTATION"))
    #expect(result.intentPrediction.intent == .healthcare)
    #expect(result.categoryPrediction?.categoryId == "healthcare")
}

@Test func ruleEngine_healthcare_medplus() {
    let result = engine().evaluate(makeFeatures(description: "MEDPLUS PHARMACY ORDER"))
    #expect(result.intentPrediction.intent == .healthcare)
}

@Test func ruleEngine_healthcare_netmeds() {
    let result = engine().evaluate(makeFeatures(description: "NETMEDS ONLINE PHARMACY"))
    #expect(result.intentPrediction.intent == .healthcare)
}

@Test func ruleEngine_healthcare_medical() {
    let result = engine().evaluate(makeFeatures(description: "MEDICAL BILL CLINIC PAYMENT"))
    #expect(result.intentPrediction.intent == .healthcare)
}

// MARK: - Investment (Stocks)

@Test func ruleEngine_investment_zerodha() {
    let result = engine().evaluate(makeFeatures(description: "ZERODHA STOCK PURCHASE NSE"))
    #expect(result.intentPrediction.intent == .investment)
    #expect(result.categoryPrediction?.categoryId == "transfers")
}

@Test func ruleEngine_investment_demat() {
    let result = engine().evaluate(makeFeatures(description: "DEMAT ACCOUNT SHARES PURCHASE"))
    #expect(result.intentPrediction.intent == .investment)
}

// MARK: - Confidence Bounds

@Test func ruleEngine_confidenceAlwaysBetweenZeroAndOne() {
    let descriptions = [
        "SALARY CREDIT JUNE 2026",
        "UPI-AMERICAN EXPRESS-AEBC373",
        "SIP GROWW MONTHLY",
        "NETFLIX SUBSCRIPTION",
        "ATM WITHDRAWAL HDFC",
        "SWIGGY ORDER 999",
        "SOME COMPLETELY UNKNOWN MERCHANT XYZ",
    ]
    let eng = engine()
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

@Test func ruleEngine_unknown_randomMerchant() {
    let result = engine().evaluate(makeFeatures(description: "XYZ CORP ABCDEF RANDOM 9999"))
    #expect(result.intentPrediction.intent == .unknown)
    #expect(result.intentPrediction.confidence < 0.5)
}

@Test func ruleEngine_catchAll_creditFallback() {
    let result = engine().evaluate(
        makeFeatures(description: "UNKNOWN CREDIT ENTRY 777", isDebit: false,
                     hasPayrollIndicator: false, hasRefundIndicator: false)
    )
    #expect(result.intentPrediction.intent == .income)
    #expect(result.categoryPrediction?.categoryId == "income")
}

// MARK: - Rule Priority Ordering

@Test func ruleEngine_salary_takesOverCreditCatchall() {
    // Salary rule (priority 1) must win over credit catch-all (priority 40)
    let result = engine().evaluate(makeFeatures(description: "SALARY CREDIT WIPRO", isDebit: false))
    #expect(result.intentPrediction.intent == .salary)
    #expect(result.matchedRuleId != "catchall.credit")
}

@Test func ruleEngine_refund_takesOverTransfer() {
    // Refund (priority 3) must win over transfer (priority 15) even if UPI present
    let result = engine().evaluate(
        makeFeatures(description: "REFUND NEFT AMAZON RETURN",
                     hasRefundIndicator: true,
                     hasTransferIndicator: true)
    )
    #expect(result.intentPrediction.intent == .refund)
}

@Test func ruleEngine_sip_takesOverTransfer() {
    // SIP (priority 6) must win over generic transfer (priority 15)
    let result = engine().evaluate(
        makeFeatures(description: "SIP NACH DEBIT AXIS MF",
                     hasTransferIndicator: true)
    )
    #expect(result.intentPrediction.intent == .mutualFundSIP)
}

// MARK: - Intent Count (all intents covered)

@Test func ruleEngine_allIntentsCovered_inBuiltInRules() {
    let allIntents = TransactionIntent.allCases.filter { $0 != .unknown }
    let ruleOutcomeIntents = Set(BuiltInRules.all.map(\.outcome.intent))
    for intent in allIntents {
        #expect(ruleOutcomeIntents.contains(intent), "No rule covers intent: \(intent.rawValue)")
    }
}

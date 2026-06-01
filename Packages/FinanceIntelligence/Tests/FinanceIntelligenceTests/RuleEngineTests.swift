@testable import FinanceIntelligence
import Testing

// MARK: - Salary

@Test
func ruleEngine_salaryCredit_indicatorAndCredit() {
    let result = makeRuleEngine().evaluate(makeFeatures(description: "SALARY CREDIT JUNE 2026", isDebit: false))
    #expect(result.intentPrediction.intent == .salary)
    #expect(result.intentPrediction.confidence >= 0.93)
    #expect(result.categoryPrediction?.categoryId == "income")
    #expect(result.matchedRuleId == "income.salary")
}

@Test
func ruleEngine_salary_hdfc() {
    let result = makeRuleEngine().evaluate(makeFeatures(description: "SALARY HDFC BANK JUNE", isDebit: false))
    #expect(result.intentPrediction.intent == .salary)
    #expect(result.categoryPrediction?.categoryId == "income")
}

@Test
func ruleEngine_salary_payroll() {
    let features = makeFeatures(description: "PAYROLL DEPOSIT TATA CONSULTANCY", isDebit: false)
    let result = makeRuleEngine().evaluate(features)
    #expect(result.intentPrediction.intent == .salary)
    #expect(result.intentPrediction.confidence >= 0.90)
}

@Test
func ruleEngine_salary_wages() {
    let result = makeRuleEngine().evaluate(makeFeatures(description: "WAGES PAYMENT INFOSYS", isDebit: false))
    #expect(result.intentPrediction.intent == .salary)
}

@Test
func ruleEngine_salary_stipend() {
    let result = makeRuleEngine().evaluate(makeFeatures(description: "STIPEND CREDIT IIT DELHI", isDebit: false))
    #expect(result.intentPrediction.intent == .salary)
}

// MARK: - Refund

@Test
func ruleEngine_refund_amazon() {
    let result = makeRuleEngine().evaluate(makeFeatures(description: "REFUND FROM AMAZON ORDER 12345", isDebit: false))
    #expect(result.intentPrediction.intent == .refund)
    #expect(result.intentPrediction.confidence >= 0.88)
    #expect(result.categoryPrediction?.categoryId == "income")
}

@Test
func ruleEngine_refund_reversal() {
    let result = makeRuleEngine().evaluate(makeFeatures(description: "REVERSAL ZOMATO TXN 98765"))
    #expect(result.intentPrediction.intent == .refund)
}

@Test
func ruleEngine_refund_flipkart() {
    let result = makeRuleEngine().evaluate(makeFeatures(description: "REFUND FLIPKART ELECTRONICS"))
    #expect(result.intentPrediction.intent == .refund)
}

@Test
func ruleEngine_refund_chargeback() {
    let result = makeRuleEngine().evaluate(makeFeatures(description: "CHARGEBACK PROCESSED VISA"))
    #expect(result.intentPrediction.intent == .refund)
}

@Test
func ruleEngine_refund_swiggy() {
    let result = makeRuleEngine().evaluate(makeFeatures(description: "REVERSAL SWIGGY ORDER CANCELLED"))
    #expect(result.intentPrediction.intent == .refund)
}

// MARK: - Cashback

@Test
func ruleEngine_cashback_reward() {
    let result = makeRuleEngine().evaluate(
        makeFeatures(description: "CASHBACK RECEIVED HDFC", isDebit: false, hasRefundIndicator: false)
    )
    #expect(result.intentPrediction.intent == .cashback)
}

@Test
func ruleEngine_cashback_rewardCredit() {
    let result = makeRuleEngine().evaluate(
        makeFeatures(description: "REWARD CREDIT AMEX CARD", isDebit: false, hasRefundIndicator: false)
    )
    #expect(result.intentPrediction.intent == .cashback)
}

// MARK: - Credit Card Payment

@Test
func ruleEngine_creditCard_amexShort() {
    let result = makeRuleEngine().evaluate(makeFeatures(description: "AMEX PAYMENT DUE"))
    #expect(result.intentPrediction.intent == .creditCardPayment)
}

@Test
func ruleEngine_creditCard_hdfcCC() {
    let result = makeRuleEngine().evaluate(makeFeatures(description: "HDFC CC PAYMENT AUTOPAY"))
    #expect(result.intentPrediction.intent == .creditCardPayment)
}

@Test
func ruleEngine_creditCard_sbiCard() {
    let result = makeRuleEngine().evaluate(makeFeatures(description: "SBI CARD PAYMENT BILL"))
    #expect(result.intentPrediction.intent == .creditCardPayment)
}

@Test
func ruleEngine_creditCard_cardPayment() {
    let result = makeRuleEngine().evaluate(makeFeatures(description: "CREDIT CARD PAYMENT BILLDESK"))
    #expect(result.intentPrediction.intent == .creditCardPayment)
}

// MARK: - Mutual Fund SIP

@Test
func ruleEngine_sip_groww() {
    let result = makeRuleEngine().evaluate(makeFeatures(description: "SIP DEBIT GROWW MUTUAL FUND"))
    #expect(result.intentPrediction.intent == .mutualFundSIP)
    #expect(result.intentPrediction.confidence >= 0.90)
    #expect(result.categoryPrediction?.categoryId == "investments")
}

@Test
func ruleEngine_sip_kuvera() {
    let result = makeRuleEngine().evaluate(makeFeatures(description: "KUVERA SIP NIFTY 50"))
    #expect(result.intentPrediction.intent == .mutualFundSIP)
}

@Test
func ruleEngine_sip_nach() {
    let result = makeRuleEngine().evaluate(makeFeatures(description: "NACH DEBIT SBI MF"))
    #expect(result.intentPrediction.intent == .mutualFundSIP)
}

@Test
func ruleEngine_sip_miraeasset() {
    let result = makeRuleEngine().evaluate(makeFeatures(description: "MIRAE ASSET SIP MONTHLY"))
    #expect(result.intentPrediction.intent == .mutualFundSIP)
}

@Test
func ruleEngine_sip_nippon() {
    let result = makeRuleEngine().evaluate(makeFeatures(description: "NIPPON INDIA MUTUAL FUND SIP"))
    #expect(result.intentPrediction.intent == .mutualFundSIP)
}

// MARK: - Insurance

@Test
func ruleEngine_insurance_lic() {
    let result = makeRuleEngine().evaluate(makeFeatures(description: "LIC PREMIUM PAYMENT"))
    #expect(result.intentPrediction.intent == .insurance)
    #expect(result.intentPrediction.confidence >= 0.90)
    #expect(result.categoryPrediction?.categoryId == "insurance")
}

@Test
func ruleEngine_insurance_maxLife() {
    let result = makeRuleEngine().evaluate(makeFeatures(description: "MAX LIFE INSURANCE PREMIUM"))
    #expect(result.intentPrediction.intent == .insurance)
}

@Test
func ruleEngine_insurance_starHealth() {
    let result = makeRuleEngine().evaluate(makeFeatures(description: "STAR HEALTH POLICY RENEWAL"))
    #expect(result.intentPrediction.intent == .insurance)
}

@Test
func ruleEngine_insurance_hdfcLife() {
    let result = makeRuleEngine().evaluate(makeFeatures(description: "HDFC LIFE INSURANCE MONTHLY"))
    #expect(result.intentPrediction.intent == .insurance)
}

@Test
func ruleEngine_insurance_bajajAllianz() {
    let result = makeRuleEngine().evaluate(makeFeatures(description: "BAJAJ ALLIANZ INSURANCE DEBIT"))
    #expect(result.intentPrediction.intent == .insurance)
}

// MARK: - Cash Withdrawal

@Test
func ruleEngine_atm_withdrawal() {
    let result = makeRuleEngine().evaluate(makeFeatures(description: "ATM WITHDRAWAL HDFC BANK"))
    #expect(result.intentPrediction.intent == .cashWithdrawal)
    #expect(result.intentPrediction.confidence >= 0.90)
    #expect(result.categoryPrediction?.categoryId == "atm")
}

@Test
func ruleEngine_atm_cashWithdrawal() {
    let result = makeRuleEngine().evaluate(makeFeatures(description: "CASH WITHDRAWAL SBI ATM PUNE"))
    #expect(result.intentPrediction.intent == .cashWithdrawal)
}

@Test
func ruleEngine_atm_icici() {
    let result = makeRuleEngine().evaluate(makeFeatures(description: "ATM CASH ICICI BANK 1234"))
    #expect(result.intentPrediction.intent == .cashWithdrawal)
}

// MARK: - Rent

@Test
func ruleEngine_rent_generic() {
    let result = makeRuleEngine().evaluate(
        makeFeatures(description: "RENT PAYMENT RITIK GUPTA", hasTransferIndicator: false)
    )
    #expect(result.intentPrediction.intent == .rent)
    #expect(result.categoryPrediction?.categoryId == "housing")
}

@Test
func ruleEngine_rent_houseRent() {
    let result = makeRuleEngine().evaluate(
        makeFeatures(description: "HOUSE RENT OCTOBER 2026", hasTransferIndicator: false)
    )
    #expect(result.intentPrediction.intent == .rent)
}

@Test
func ruleEngine_rent_flatRent() {
    let result = makeRuleEngine().evaluate(
        makeFeatures(description: "FLAT RENT BANGALORE SECTOR 5", hasTransferIndicator: false)
    )
    #expect(result.intentPrediction.intent == .rent)
}

// MARK: - Loan Payment

@Test
func ruleEngine_loan_emi() {
    let result = makeRuleEngine().evaluate(makeFeatures(description: "LOAN EMI HDFC BANK"))
    #expect(result.intentPrediction.intent == .loanPayment)
    #expect(result.categoryPrediction?.categoryId == "fees")
}

@Test
func ruleEngine_loan_homeLoan() {
    let result = makeRuleEngine().evaluate(makeFeatures(description: "HOME LOAN EMI PAYMENT SBI"))
    #expect(result.intentPrediction.intent == .loanPayment)
}

@Test
func ruleEngine_loan_bajaj() {
    let result = makeRuleEngine().evaluate(makeFeatures(description: "BAJAJ FINANCE EMI DEBIT"))
    #expect(result.intentPrediction.intent == .loanPayment)
}

// MARK: - Interest Payment

@Test
func ruleEngine_interest_charge() {
    let result = makeRuleEngine().evaluate(makeFeatures(description: "INTEREST CHARGE CREDIT CARD OCT"))
    #expect(result.intentPrediction.intent == .interestPayment)
}

@Test
func ruleEngine_interest_finance_charge() {
    let result = makeRuleEngine().evaluate(makeFeatures(description: "FINANCE CHARGE APPLIED AMEX"))
    #expect(result.intentPrediction.intent == .interestPayment)
}

// MARK: - Transfer

@Test
func ruleEngine_transfer_neft() {
    let result = makeRuleEngine().evaluate(makeFeatures(description: "NEFT TO SEEMA GOEL REF 8888"))
    #expect(result.intentPrediction.intent == .transfer)
    #expect(result.categoryPrediction?.categoryId == "transfers")
}

@Test
func ruleEngine_transfer_imps() {
    let result = makeRuleEngine().evaluate(makeFeatures(description: "IMPS AMAN PANDEY 5000"))
    #expect(result.intentPrediction.intent == .transfer)
}

@Test
func ruleEngine_transfer_upi() {
    let result = makeRuleEngine().evaluate(makeFeatures(description: "UPI-AMAN PANDEY-AMAN@UPI-REF123"))
    #expect(result.intentPrediction.intent == .transfer)
}

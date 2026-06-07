@testable import FinanceIntelligence
import Foundation

func makeFeatures(
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
        hasCreditCardPaymentIndicator: false,
        institutionHint: nil,
        ledgerKindHint: nil
    )
}

func makeRuleEngine() -> RuleEngine {
    RuleEngine()
}

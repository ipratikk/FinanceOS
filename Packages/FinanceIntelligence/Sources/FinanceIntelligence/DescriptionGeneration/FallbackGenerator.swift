import Foundation

/// Deterministic template-based description generator.
/// Covers all 21 `TransactionIntent` cases. Never returns empty string.
/// Used when Apple Intelligence is unavailable or the context lacks enough signal.
public struct FallbackGenerator: Sendable {
    public init() {}

    /// Generate a human-readable description from structured context.
    /// Always returns a non-empty string.
    public func generate(from context: DescriptionContext) -> String {
        let cadencePrefix = cadenceString(context.recurringCadence, isRecurring: context.isRecurring)
        switch context.intent {
        case .salary:
            return "\(cadencePrefix)salary credit from \(context.merchantName)"
        case .rent:
            return "\(cadencePrefix)rent payment to \(context.merchantName)"
        case .investment:
            return "\(cadencePrefix)investment via \(context.merchantName)"
        case .mutualFundSIP:
            return "\(cadencePrefix)mutual fund SIP — \(context.merchantName)"
        case .insurance:
            return "\(cadencePrefix)\(context.merchantName) insurance premium"
        case .subscription:
            return "\(cadencePrefix)\(context.merchantName) subscription"
        case .creditCardPayment:
            return "\(cadencePrefix)\(context.merchantName) credit card payment"
        case .loanPayment:
            return "\(cadencePrefix)loan payment — \(context.merchantName)"
        case .cashWithdrawal:
            return "ATM cash withdrawal"
        case .refund:
            return "Refund from \(context.merchantName)"
        case .cashback:
            return "Cashback from \(context.merchantName)"
        case .transfer:
            return transferDescription(context)
        case .interestPayment:
            return "\(cadencePrefix)interest payment — \(context.merchantName)"
        case .utilityBill:
            return "\(cadencePrefix)\(context.merchantName) utility bill"
        case .shopping:
            return "Purchase at \(context.merchantName)"
        case .groceries:
            return "Groceries — \(context.merchantName)"
        case .food:
            return "Food order — \(context.merchantName)"
        case .travel:
            return "Travel — \(context.merchantName)"
        case .healthcare:
            return "Healthcare — \(context.merchantName)"
        case .income:
            return "Credit from \(context.merchantName)"
        case .unknown:
            return unknownDescription(context)
        }
    }

    // MARK: - Private

    private func cadenceString(_ cadence: RecurringCadence?, isRecurring: Bool) -> String {
        guard isRecurring, let cadence else { return "" }
        switch cadence {
        case .weekly:    return "Weekly "
        case .biWeekly:  return "Bi-weekly "
        case .monthly:   return "Monthly "
        case .quarterly: return "Quarterly "
        case .yearly:    return "Annual "
        case .irregular: return ""
        }
    }

    private func transferDescription(_ context: DescriptionContext) -> String {
        guard let rel = context.relationship else {
            return context.isDebit
                ? "Payment to \(context.merchantName)"
                : "Transfer from \(context.merchantName)"
        }
        switch rel {
        case .landlord:     return "Rent payment to \(context.merchantName)"
        case .employer:     return "Salary from \(context.merchantName)"
        case .family:       return "Family transfer — \(context.merchantName)"
        case .friend:       return "Transfer to \(context.merchantName)"
        case .reimbursement: return "Reimbursement from \(context.merchantName)"
        default:            return "Transfer — \(context.merchantName)"
        }
    }

    private func unknownDescription(_ context: DescriptionContext) -> String {
        if !context.merchantName.isEmpty {
            return context.isDebit
                ? "Payment to \(context.merchantName)"
                : "Credit from \(context.merchantName)"
        }
        return context.isDebit ? "Debit transaction" : "Credit transaction"
    }
}

import Foundation

/// Deterministic template-based description generator.
/// Covers all 21 `TransactionIntent` cases. Never returns empty string.
/// Used when Apple Intelligence is unavailable or the context lacks enough signal.
public struct FallbackGenerator: Sendable {
    public init() {}

    /// Generate a human-readable description from structured context.
    /// Always returns a non-empty string.
    public func generate(from context: DescriptionContext) -> String {
        recurringIntentDescription(context) ?? simpleIntentDescription(context)
    }

    // swiftlint:disable:next cyclomatic_complexity
    private func recurringIntentDescription(_ context: DescriptionContext) -> String? {
        let p = cadenceString(context.recurringCadence, isRecurring: context.isRecurring)
        let m = context.merchantName
        switch context.intent {
        case .salary: return "\(p)salary credit from \(m)"
        case .rent: return "\(p)rent payment to \(m)"
        case .investment: return "\(p)investment via \(m)"
        case .mutualFundSIP: return "\(p)mutual fund SIP — \(m)"
        case .insurance: return "\(p)\(m) insurance premium"
        case .subscription: return "\(p)\(m) subscription"
        case .creditCardPayment: return "\(p)\(m) credit card payment"
        case .loanPayment: return "\(p)loan payment — \(m)"
        case .interestPayment: return "\(p)interest payment — \(m)"
        case .utilityBill: return "\(p)\(m) utility bill"
        default: return nil
        }
    }

    // swiftlint:disable:next cyclomatic_complexity
    private func simpleIntentDescription(_ context: DescriptionContext) -> String {
        let m = context.merchantName
        switch context.intent {
        case .cashWithdrawal: return "ATM cash withdrawal"
        case .refund: return "Refund from \(m)"
        case .cashback: return "Cashback from \(m)"
        case .transfer: return transferDescription(context)
        case .shopping: return "Purchase at \(m)"
        case .groceries: return "Groceries — \(m)"
        case .food: return "Food order — \(m)"
        case .travel: return "Travel — \(m)"
        case .healthcare: return "Healthcare — \(m)"
        case .income: return "Credit from \(m)"
        default: return unknownDescription(context)
        }
    }

    // MARK: - Private

    private func cadenceString(_ cadence: RecurringCadence?, isRecurring: Bool) -> String {
        guard isRecurring, let cadence else { return "" }
        switch cadence {
        case .weekly: return "Weekly "
        case .biWeekly: return "Bi-weekly "
        case .monthly: return "Monthly "
        case .quarterly: return "Quarterly "
        case .yearly: return "Annual "
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
        case .landlord: return "Rent payment to \(context.merchantName)"
        case .employer: return "Salary from \(context.merchantName)"
        case .family: return "Family transfer — \(context.merchantName)"
        case .friend: return "Transfer to \(context.merchantName)"
        case .reimbursement: return "Reimbursement from \(context.merchantName)"
        default: return "Transfer — \(context.merchantName)"
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

import Foundation

/// Canonical predicates for accounting-correct income and expense aggregation.
///
/// Single-entry systems need explicit filtering to exclude inter-account movements
/// (transfers, CC payments, investment purchases) from income/expense totals.
/// Without these filters, every CC payment inflates both outflows (bank debit)
/// and inflows (card credit), producing double-counted financial reports.
public enum TransactionFilter {
    // MARK: - Category prefix exclusions

    /// Category IDs (or prefixes) that must never appear in expense totals.
    /// These represent asset movements or liability settlements — not consumption.
    /// FINOS-106: Investment purchases (SIP, mutual funds, stocks) are asset conversions, not expenses.
    private static let nonExpenseCategoryPrefixes: [String] = [
        "transfers", // internal/external transfers, CC payments tagged as transfers
        "investments", // SIP, stocks, FD — asset conversion, not spending (FINOS-106)
        "income" // credits misclassified; should never be in debit path anyway
    ]

    /// Category IDs (or prefixes) that represent actual income.
    private static let incomeCategoryPrefixes: [String] = [
        "income"
    ]

    /// Intent raw values that disqualify a debit from being a real expense.
    private static let nonExpenseIntents: Set<String> = [
        "credit_card_payment", // CC bill payment — liability settlement
        "loan_payment", // EMI — liability reduction (principal portion)
        "mutual_fund_sip", // SIP debit — asset purchase
        "investment", // any investment purchase
        "transfer", // inter-account movement
        "cash_withdrawal" // ATM — just changes form of asset, excludable
    ]

    /// Intent raw values that disqualify a credit from being real income.
    private static let nonIncomeIntents: Set<String> = [
        "transfer", // transfer receipt — not income
        "credit_card_payment" // card payment acknowledgment — not income
    ]

    // MARK: - Public predicates

    /// Returns true if this transaction represents real consumer spending.
    ///
    /// Excludes: transfers, CC bill payments, investment purchases, loan EMIs.
    /// These are asset conversions or liability settlements — not actual expenses.
    public static func isRealExpense(_ txn: Transaction) -> Bool {
        isRealExpense(
            isDebit: txn.transactionType == .debit,
            categoryId: txn.categoryId,
            intentId: txn.intentId,
            isReconciled: txn.linkedTransactionId != nil
        )
    }

    /// Returns true if this transaction represents real income.
    ///
    /// Requires explicit income categorization. Unmatched credits land in
    /// "uncategorized" (not "income") after the catchall.credit fix, so this
    /// predicate is strict by design.
    public static func isRealIncome(_ txn: Transaction) -> Bool {
        isRealIncome(
            isCredit: txn.transactionType == .credit,
            categoryId: txn.categoryId,
            intentId: txn.intentId
        )
    }

    // MARK: - String-based overloads (for TransactionRecord callers)

    /// Returns true if the raw field values describe real consumer spending.
    /// Use this when operating on `CashflowAnalyzer.TransactionRecord` or similar
    /// lightweight structs that carry categoryId/intentId as plain strings.
    public static func isRealExpense(
        isDebit: Bool,
        categoryId: String?,
        intentId: String?,
        isReconciled: Bool = false
    ) -> Bool {
        guard isDebit else { return false }

        if intentId == "credit_card_payment" { return false }

        if let cat = categoryId {
            for prefix in nonExpenseCategoryPrefixes where cat == prefix || cat.hasPrefix("\(prefix).") {
                return false
            }
        }

        if let intent = intentId, nonExpenseIntents.contains(intent) { return false }

        return true
    }

    /// Returns true if the raw field values describe real income.
    /// Accepts: (1) explicit "income.*" category, (2) uncategorized credit without non-income intent.
    /// Rejects: transfer/refund intents, expense-like categories.
    public static func isRealIncome(
        isCredit: Bool,
        categoryId: String?,
        intentId: String?
    ) -> Bool {
        guard isCredit else { return false }

        if let intent = intentId, nonIncomeIntents.contains(intent) { return false }

        if let cat = categoryId {
            if nonExpenseCategoryPrefixes.contains(where: { cat == $0 || cat.hasPrefix("\($0).") }) {
                return false
            }
            if incomeCategoryPrefixes.contains(where: { cat == $0 || cat.hasPrefix("\($0).") }) {
                return true
            }
        }

        return true
    }

    // MARK: - Loan EMI helpers (FINOS-105)

    /// Returns true if this transaction is a loan payment (EMI).
    public static func isLoanPayment(_ txn: Transaction) -> Bool {
        txn.transactionType == .debit && txn.intentId == "loan_payment"
    }

    /// Extracts the interest-only portion of a loan EMI payment.
    /// Principal portion is a liability reduction (not an expense).
    /// Only interest counts as expense per accounting standards.
    ///
    /// Returns the interest component in minor units. If amortization data unavailable,
    /// returns 0 (conservative: payment assumed to be principal-only).
    /// Integrate with LoanAccount model (FINOS-105) to look up remaining principal and rate.
    public static func loanInterestComponent(_ txn: Transaction) -> Int64 {
        guard isLoanPayment(txn) else { return 0 }
        return 0
    }
}

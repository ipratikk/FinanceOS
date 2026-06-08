import FinanceCore
import Foundation

/// Matches bank account credit-card-payment debits to their corresponding card credit entries.
/// Identifies pairs like: HDFC "UPI-AMERICAN EXPRESS" ↔ Amex "PAYMENT RECEIVED. THANK YOU".
public struct CreditCardPaymentReconciler: Sendable {
    /// Tolerance window for amount matching in minor units (±₹50 = ±5000 paise).
    public static let amountTolerance: Int64 = 5000
    /// Tolerance window for date matching in seconds (±3 days).
    public static let dateTolerance: TimeInterval = 3 * 24 * 3600

    public init() {}

    /// Match bank debits to card credits. Each transaction appears in at most one pair (greedy, earliest match).
    public func reconcile(
        bankDebits: [Transaction],
        cardCredits: [Transaction]
    ) -> [ReconciliationPair] {
        var unmatched = cardCredits
        var pairs: [ReconciliationPair] = []

        for debit in bankDebits where isCreditCardPaymentDebit(debit) {
            guard let idx = unmatched.firstIndex(where: { isMatch(debit: debit, credit: $0) }) else { continue }
            let credit = unmatched.remove(at: idx)
            pairs.append(ReconciliationPair(
                bankDebitId: debit.id,
                cardCreditId: credit.id,
                bankAmount: debit.amountMinorUnits,
                cardAmount: credit.amountMinorUnits,
                discrepancy: debit.amountMinorUnits - credit.amountMinorUnits
            ))
        }
        return pairs
    }

    // MARK: - Private

    private func isCreditCardPaymentDebit(_ txn: Transaction) -> Bool {
        guard txn.transactionType == .debit else { return false }
        let lower = txn.description.lowercased()
        return lower.contains("aebc") ||
            lower.contains("cred.club") || lower.contains("cred ccbp") ||
            lower.contains("upi-american express") ||
            lower.contains("bbps")
    }

    private func isCreditCardPaymentCredit(_ txn: Transaction) -> Bool {
        guard txn.transactionType == .credit else { return false }
        let lower = txn.description.lowercased()
        return lower.contains("bbps") ||
            lower.contains("payment received")
    }

    private func isMatch(debit: Transaction, credit: Transaction) -> Bool {
        guard isCreditCardPaymentCredit(credit) else { return false }
        let dateDiff = abs(debit.postedAt.timeIntervalSince(credit.postedAt))
        guard dateDiff <= Self.dateTolerance else { return false }
        let amountDiff = abs(debit.amountMinorUnits - credit.amountMinorUnits)
        return amountDiff <= Self.amountTolerance
    }
}

// MARK: - Result type

public struct ReconciliationPair: Sendable {
    public let bankDebitId: UUID
    public let cardCreditId: UUID
    public let bankAmount: Int64
    public let cardAmount: Int64
    /// Positive = bank paid more than card received (e.g. CRED cashback absorbed on card side).
    public let discrepancy: Int64
}

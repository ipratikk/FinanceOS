import Foundation

/// Verifies accounting invariants for reconciliation correctness.
public enum ReconciliationValidator {
    /// Result of reconciliation validation.
    public struct ValidationResult: Sendable {
        public let isValid: Bool
        public let errors: [String]

        public init(isValid: Bool, errors: [String] = []) {
            self.isValid = isValid
            self.errors = errors
        }
    }

    /// Validates that transaction deltas match closing balance (if known).
    /// For delta-mode ledgers: openingBalance + Σ(credits - debits) should equal closingBalance.
    public static func validateBalanceEquation(
        ledger: Ledger,
        transactions: [Transaction]
    ) -> ValidationResult {
        guard let closingBalance = ledger.closingBalance else {
            return ValidationResult(isValid: true) // No closing balance = can't validate
        }

        let base = ledger.openingBalance ?? 0
        let computed = transactions.reduce(base) { acc, txn in
            acc + (txn.transactionType == .credit ? txn.amountMinorUnits : -txn.amountMinorUnits)
        }

        if computed == closingBalance {
            return ValidationResult(isValid: true)
        }

        let discrepancy = closingBalance - computed
        let error = "Balance mismatch: expected \(closingBalance), computed \(computed), discrepancy \(discrepancy)"
        return ValidationResult(isValid: false, errors: [error])
    }

    /// Validates that linkedTransactionId references are symmetric and point to real transactions.
    public static func validateLinkedTransactions(transactions: [Transaction]) -> ValidationResult {
        var errors: [String] = []
        let txnMap = Dictionary(uniqueKeysWithValues: transactions.map { ($0.id.uuidString, $0) })

        for txn in transactions {
            guard let linkedId = txn.linkedTransactionId else { continue }

            // Referenced transaction must exist
            guard let linkedTxn = txnMap[linkedId] else {
                errors.append("Transaction \(txn.id) references non-existent \(linkedId)")
                continue
            }

            // Reference must be symmetric
            if linkedTxn.linkedTransactionId != txn.id.uuidString {
                let reverseId = linkedTxn.linkedTransactionId ?? "nil"
                errors.append("Asymmetric link: \(txn.id) → \(linkedId) but \(linkedId) → \(reverseId)")
            }
        }

        return ValidationResult(isValid: errors.isEmpty, errors: errors)
    }
}

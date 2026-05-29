import FinanceParsers
import Foundation

/// Stateless deduplication utility used during import preview to surface likely duplicates.
/// Hashes on date (day boundary) + absolute amount + normalised description — intentionally
/// ignores ledger ownership so the same transaction isn't double-counted across re-imports.
public enum TransactionDeduplicator {
    /// Shared formatter; `nonisolated(unsafe)` because ISO8601DateFormatter is not Sendable.
    private nonisolated(unsafe) static let iso8601 = ISO8601DateFormatter()

    /// Returns true when `parsed` and `existing` represent the same real-world transaction.
    public static func isSame(parsed: ParsedTransaction, existing: Transaction) -> Bool {
        hash(parsed) == hash(existing)
    }

    /// Canonical fingerprint for a parsed transaction: `<day>|<absAmount>|<normDesc>`.
    private static func hash(_ txn: ParsedTransaction) -> String {
        let dateStr = iso8601.string(from: Calendar.current.startOfDay(for: txn.postedAt))
        let amountStr = String(abs(txn.amountMinorUnits))
        let descStr = txn.description.trimmingCharacters(in: .whitespaces).lowercased()
        return "\(dateStr)|\(amountStr)|\(descStr)"
    }

    /// Canonical fingerprint for a persisted transaction, using the same scheme as the parsed variant.
    private static func hash(_ txn: Transaction) -> String {
        let dateStr = iso8601.string(from: Calendar.current.startOfDay(for: txn.postedAt))
        let amountStr = String(abs(txn.amountMinorUnits))
        let descStr = txn.description.trimmingCharacters(in: .whitespaces).lowercased()
        return "\(dateStr)|\(amountStr)|\(descStr)"
    }
}

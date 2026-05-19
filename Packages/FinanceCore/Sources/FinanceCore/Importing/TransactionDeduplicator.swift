import FinanceParsers
import Foundation

public enum TransactionDeduplicator {
    public static func isSame(parsed: ParsedTransaction, existing: Transaction) -> Bool {
        hash(parsed) == hash(existing)
    }

    private static func hash(_ txn: ParsedTransaction) -> String {
        let dateStr = ISO8601DateFormatter().string(from: Calendar.current.startOfDay(for: txn.postedAt))
        let amountStr = String(abs(txn.amountMinorUnits))
        let descStr = txn.description.trimmingCharacters(in: .whitespaces).lowercased()
        return "\(dateStr)|\(amountStr)|\(descStr)"
    }

    private static func hash(_ txn: Transaction) -> String {
        let dateStr = ISO8601DateFormatter().string(from: Calendar.current.startOfDay(for: txn.postedAt))
        let amountStr = String(abs(txn.amountMinorUnits))
        let descStr = txn.description.trimmingCharacters(in: .whitespaces).lowercased()
        return "\(dateStr)|\(amountStr)|\(descStr)"
    }
}

import FinanceCore
import FinanceParsers
import FinanceUI
import Foundation

protocol DuplicateDetectingProtocol: Sendable {
    func detect(
        statements: [ParsedStatement],
        existingTransactions: [Transaction]
    ) -> (skipAll: Set<Int>, inDB: Set<Int>)
}

/// Pure value-type deduplication engine. No async, no MainActor — fully unit-testable.
/// Extracted from ImportViewModel to isolate the hash-based dedup algorithm.
struct ImportDuplicateDetector: DuplicateDetectingProtocol {
    /// Returns two index sets over the flattened transaction list across all statements:
    /// - `skipAll`: indices to skip on import (within-batch duplicates + already-in-DB)
    /// - `inDB`: subset of `skipAll` that are already in the database
    func detect(
        statements: [ParsedStatement],
        existingTransactions: [Transaction]
    ) -> (skipAll: Set<Int>, inDB: Set<Int>) {
        var skipAll = Set<Int>()
        var inDB = Set<Int>()
        let existingHashes = Set(existingTransactions.map { hash($0) })
        var seen = Set<String>()

        var flatIndex = 0
        for statement in statements {
            for parsedTxn in statement.transactions {
                let txnHash = hash(parsedTxn)
                let isFirstSeen = seen.insert(txnHash).inserted
                if !isFirstSeen {
                    skipAll.insert(flatIndex)
                } else if existingHashes.contains(txnHash) {
                    skipAll.insert(flatIndex)
                    inDB.insert(flatIndex)
                }
                flatIndex += 1
            }
        }

        return (skipAll, inDB)
    }

    private func hash(_ txn: ParsedTransaction) -> String {
        txn.sourceFingerprint
    }

    private func hash(_ txn: Transaction) -> String {
        if let fp = txn.sourceFingerprint { return fp }
        let dateStr = FormatterCache.iso8601.string(from: Calendar.current.startOfDay(for: txn.postedAt))
        let descStr = txn.description
            .components(separatedBy: .whitespaces).filter { !$0.isEmpty }.joined().lowercased()
        return "\(dateStr)|\(String(abs(txn.amountMinorUnits)))|\(descStr)"
    }
}

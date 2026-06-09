import FinanceCore
import Foundation

/// Summary produced by ``TransactionsViewModel/runRecalculation()``.
/// Captures accounting validation findings and expense/income totals.
struct RecalculationResult {
    // MARK: - Linked transaction validation

    let orphanedLinkCount: Int
    let asymmetricLinkCount: Int

    // MARK: - Balance equation validation (per ledger)

    /// Number of ledgers where openingBalance + Σ(credits - debits) ≠ closingBalance.
    let balanceMismatchCount: Int
    let balanceMismatchMessages: [String]

    // MARK: - Spending totals (post-filter)

    /// Count of transactions passing TransactionFilter.isRealExpense.
    let realExpenseCount: Int
    /// Sum of real-expense amounts in minor units.
    let realExpenseTotalMinorUnits: Int64
    /// Count of transactions excluded from expenses (transfers, investments, CC payments).
    let excludedFromExpensesCount: Int

    // MARK: - Income totals (post-filter)

    let realIncomeCount: Int
    let realIncomeTotalMinorUnits: Int64

    // MARK: - Overall health

    var isHealthy: Bool {
        orphanedLinkCount == 0 && asymmetricLinkCount == 0 && balanceMismatchCount == 0
    }

    var summaryMessage: String {
        if isHealthy {
            let expenseFormatted = realExpenseTotalMinorUnits.formattedAsRupees()
            let incomeFormatted = realIncomeTotalMinorUnits.formattedAsRupees()
            return """
            Accounting checks passed.

            Real expenses: \(realExpenseCount) txns (\(expenseFormatted))
            Real income: \(realIncomeCount) txns (\(incomeFormatted))
            Excluded from expenses: \(excludedFromExpensesCount) txns \
            (transfers, investments, CC payments)
            """
        }
        var lines: [String] = ["Issues found:"]
        if orphanedLinkCount > 0 {
            lines.append("  Orphaned links: \(orphanedLinkCount)")
        }
        if asymmetricLinkCount > 0 {
            lines.append("  Asymmetric links: \(asymmetricLinkCount)")
        }
        if balanceMismatchCount > 0 {
            lines.append("  Balance mismatches: \(balanceMismatchCount)")
            lines.append(contentsOf: balanceMismatchMessages.map { "    \($0)" })
        }
        return lines.joined(separator: "\n")
    }

    // MARK: - Factory

    /// Runs all accounting validators synchronously (intended for detached Task use).
    nonisolated static func compute(transactions: [Transaction], ledgers: [Ledger]) -> RecalculationResult {
        // 1. Linked transaction validation
        let linkResult = ReconciliationValidator.validateLinkedTransactions(transactions: transactions)
        let orphaned = linkResult.errors.count(where: { $0.contains("non-existent") })
        let asymmetric = linkResult.errors.count(where: { $0.contains("Asymmetric") })

        // 2. Balance equation per ledger
        let txnsByLedger = Dictionary(grouping: transactions) { $0.ledgerId }
        var balanceMismatches: [String] = []
        for ledger in ledgers {
            let ledgerTxns = txnsByLedger[ledger.id] ?? []
            let result = ReconciliationValidator.validateBalanceEquation(ledger: ledger, transactions: ledgerTxns)
            if !result.isValid {
                let prefixed = result.errors.map { "\(ledger.displayName): \($0)" }
                balanceMismatches.append(contentsOf: prefixed)
            }
        }

        // 3. Expense/income totals using canonical filter
        var realExpenseCount = 0
        var realExpenseTotal: Int64 = 0
        var excludedCount = 0
        var realIncomeCount = 0
        var realIncomeTotal: Int64 = 0

        for txn in transactions {
            if TransactionFilter.isRealExpense(txn) {
                realExpenseCount += 1
                realExpenseTotal += txn.amountMinorUnits
            } else if txn.transactionType == .debit {
                excludedCount += 1
            }
            if TransactionFilter.isRealIncome(txn) {
                realIncomeCount += 1
                realIncomeTotal += txn.amountMinorUnits
            }
        }

        return RecalculationResult(
            orphanedLinkCount: orphaned,
            asymmetricLinkCount: asymmetric,
            balanceMismatchCount: balanceMismatches.count,
            balanceMismatchMessages: balanceMismatches,
            realExpenseCount: realExpenseCount,
            realExpenseTotalMinorUnits: realExpenseTotal,
            excludedFromExpensesCount: excludedCount,
            realIncomeCount: realIncomeCount,
            realIncomeTotalMinorUnits: realIncomeTotal
        )
    }
}

// MARK: - Minor unit formatting helper

private extension Int64 {
    func formattedAsRupees() -> String {
        let major = Double(self) / 100.0
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "INR"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: major)) ?? "₹\(Int(major))"
    }
}

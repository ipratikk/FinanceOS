import FinanceCore
import FinanceUI
import Foundation

protocol AccountBalanceProtocol: Sendable {
    func computeBalance(account: Ledger, transactions: [Transaction]) -> Int64
    func computeRunningBalances(
        sortedTransactions: [Transaction],
        closingBalance: Int64,
        currencyCode: String
    ) -> [UUID: String]
}

struct AccountBalanceService: AccountBalanceProtocol {
    func computeBalance(account: Ledger, transactions: [Transaction]) -> Int64 {
        if let closing = account.closingBalance { return closing }
        let base = account.openingBalance ?? 0
        return transactions.reduce(base) { acc, txn in
            acc + (txn.transactionType == .credit ? txn.amountMinorUnits : -txn.amountMinorUnits)
        }
    }

    func computeRunningBalances(
        sortedTransactions: [Transaction],
        closingBalance: Int64,
        currencyCode: String
    ) -> [UUID: String] {
        var balance = closingBalance
        var result: [UUID: String] = [:]
        for txn in sortedTransactions {
            result[txn.id] = MoneyFormatting.formatRunningBalance(minorUnits: balance, currencyCode: currencyCode)
            balance += txn.transactionType == .debit ? txn.amountMinorUnits : -txn.amountMinorUnits
        }
        return result
    }
}

import FinanceUI
import Foundation

struct TransactionSection: Identifiable {
    let id: String
    let title: String
    let date: Date
    let rows: [TransactionRow]
    let netAmountMinorUnits: Int64

    var netAmountText: String {
        FormatterCache.formatCurrency(minorUnits: abs(netAmountMinorUnits))
    }
}

import FinanceCore
import FinanceParsers
import Foundation

struct StatementMetadata {
    let parsedTransactions: [ParsedTransaction]
    let periodStart: Date?
    let periodEnd: Date?
    let totalDebit: Int64
    let totalCredit: Int64

    init(_ transactions: [ParsedTransaction]) {
        parsedTransactions = transactions

        let dates = transactions.map(\.postedAt).sorted()
        periodStart = dates.first
        periodEnd = dates.last

        var debit: Int64 = 0
        var credit: Int64 = 0

        for transaction in transactions {
            if transaction.amountMinorUnits < 0 {
                debit -= transaction.amountMinorUnits
            } else {
                credit += transaction.amountMinorUnits
            }
        }

        totalDebit = debit
        totalCredit = credit
    }
}

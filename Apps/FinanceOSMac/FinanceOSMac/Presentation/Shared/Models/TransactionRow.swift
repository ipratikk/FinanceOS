import FinanceCore
import Foundation

struct TransactionRow: Identifiable {
    let id: UUID
    let title: String
    let subtitle: String
    let amountText: String
    let transactionType: TransactionType
    let postedAt: Date
}

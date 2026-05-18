import FinanceCore
import Foundation

struct TransactionRow: Identifiable {
    let id: UUID
    let title: String
    let subtitle: String
    let amountText: String
    let transactionType: TransactionType
    let postedAt: Date
    let runningBalance: String?

    init(
        id: UUID,
        title: String,
        subtitle: String,
        amountText: String,
        transactionType: TransactionType,
        postedAt: Date,
        runningBalance: String? = nil
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.amountText = amountText
        self.transactionType = transactionType
        self.postedAt = postedAt
        self.runningBalance = runningBalance
    }
}

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
    /// Canonical merchant name from intelligence layer. Nil before analysis completes.
    let merchantName: String?
    /// Predicted or user-corrected category ID. Nil before analysis completes.
    let categoryId: String?
    let isUserCorrected: Bool
    /// Source transaction, used for category corrections via intelligence service.
    let sourceTransaction: Transaction?

    init(
        id: UUID,
        title: String,
        subtitle: String,
        amountText: String,
        transactionType: TransactionType,
        postedAt: Date,
        runningBalance: String? = nil,
        merchantName: String? = nil,
        categoryId: String? = nil,
        isUserCorrected: Bool = false,
        sourceTransaction: Transaction? = nil
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.amountText = amountText
        self.transactionType = transactionType
        self.postedAt = postedAt
        self.runningBalance = runningBalance
        self.merchantName = merchantName
        self.categoryId = categoryId
        self.isUserCorrected = isUserCorrected
        self.sourceTransaction = sourceTransaction
    }

    /// Display name: canonical merchant name if available, else raw description.
    var displayTitle: String {
        merchantName ?? title
    }
}

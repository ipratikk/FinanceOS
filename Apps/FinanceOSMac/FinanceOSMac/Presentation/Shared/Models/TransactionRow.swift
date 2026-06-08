import FinanceCore
import Foundation

struct TransactionRow: Identifiable {
    let id: UUID
    let title: String
    let subtitle: String
    let amountText: String
    let amountMinorUnits: Int64
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
    /// Deterministic human-readable description, persisted during pipeline analysis. Nil until analyzed.
    let enrichedDescription: String?

    init(
        id: UUID,
        title: String,
        subtitle: String,
        amountText: String,
        amountMinorUnits: Int64 = 0,
        transactionType: TransactionType,
        postedAt: Date,
        runningBalance: String? = nil,
        merchantName: String? = nil,
        categoryId: String? = nil,
        isUserCorrected: Bool = false,
        sourceTransaction: Transaction? = nil,
        enrichedDescription: String? = nil
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.amountText = amountText
        self.amountMinorUnits = amountMinorUnits
        self.transactionType = transactionType
        self.postedAt = postedAt
        self.runningBalance = runningBalance
        self.merchantName = merchantName
        self.categoryId = categoryId
        self.isUserCorrected = isUserCorrected
        self.sourceTransaction = sourceTransaction
        self.enrichedDescription = enrichedDescription
    }

    /// Display name: enriched description if available, else canonical merchant name, else raw description.
    var displayTitle: String {
        enrichedDescription ?? merchantName ?? title
    }
}

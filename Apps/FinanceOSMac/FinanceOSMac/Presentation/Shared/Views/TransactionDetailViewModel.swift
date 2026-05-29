import FinanceCore
import FinanceIntelligence
import FinanceUI
import Observation
import SwiftUI

@Observable
@MainActor
final class TransactionDetailViewModel {
    private let row: TransactionRow

    var categoryId: String?
    var isUserCorrected: Bool

    init(row: TransactionRow) {
        self.row = row
        categoryId = row.categoryId
        isUserCorrected = row.isUserCorrected
    }

    var categoryDisplayName: String {
        guard let id = categoryId else { return "Uncategorized" }
        return CategoryTaxonomy.current.category(forId: id)?.displayName ?? id.capitalized
    }

    var categoryColor: Color {
        CategorySymbol.color(for: categoryId)
    }

    var categorySymbol: String {
        CategorySymbol.symbol(for: categoryId)
    }

    var showNarration: Bool {
        row.title != row.displayTitle
    }

    var postedDateText: String {
        FormatterCache.fullDayDate.string(from: row.postedAt)
    }

    var postedTimeText: String {
        FormatterCache.dayAndTime.string(from: row.postedAt)
    }

    func applyCorrection(transactionId: UUID, newCategoryId: String) {
        categoryId = newCategoryId
        isUserCorrected = true
    }
}

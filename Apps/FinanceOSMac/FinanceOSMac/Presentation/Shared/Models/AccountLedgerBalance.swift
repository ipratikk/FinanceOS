import FinanceCore
import FinanceUI
import Foundation

struct AccountLedgerBalance {
    let netMinorUnits: Int64
    let latestPostedAt: Date?

    var formattedBalance: String {
        MoneyFormatting.formatBalance(minorUnits: netMinorUnits)
    }

    var formattedDate: String? {
        guard let date = latestPostedAt else { return nil }
        return FormatterCache.slashDate.string(from: date)
    }
}

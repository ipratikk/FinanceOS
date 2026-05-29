import FinanceCore
import Foundation

struct CategorySpendSummary: Identifiable {
    let id: String
    let displayName: String
    let totalDebit: Int64
    let percentage: Double
    let transactionCount: Int

    var amountText: String {
        MoneyFormatting.formatRounded(minorUnits: totalDebit)
    }
}

struct MerchantSummary: Identifiable {
    var id: String {
        name
    }

    let name: String
    let totalDebit: Int64
    let transactionCount: Int
    let maxTotal: Int64

    var initials: String {
        let words = name.split(separator: " ")
        if words.count >= 2 {
            return String(words[0].prefix(1) + words[1].prefix(1)).uppercased()
        }
        return String(name.prefix(2)).uppercased()
    }

    var proportion: Double {
        maxTotal > 0 ? Double(totalDebit) / Double(maxTotal) : 0
    }

    var amountText: String {
        MoneyFormatting.formatRounded(minorUnits: totalDebit)
    }
}

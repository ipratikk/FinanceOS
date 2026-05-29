import FinanceCore
import Foundation

struct FluctuationRow: Identifiable {
    let id: UUID
    let merchantName: String
    let dateText: String
    let currencyCode: String
    let amountText: String
    let isDebit: Bool
    let sourceTransaction: Transaction
}

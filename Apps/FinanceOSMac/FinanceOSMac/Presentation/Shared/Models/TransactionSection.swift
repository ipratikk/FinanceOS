import Foundation

struct TransactionSection: Identifiable {
    let id: String
    let title: String
    let rows: [TransactionRow]
}

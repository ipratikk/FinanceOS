@testable import FinanceOSMac
import FinanceTesting
import SnapshotTesting
import SwiftUI
import XCTest

final class TransactionRowSnapshotTests: XCTestCase {
    let record = false

    func test_transaction_row_debit() {
        let transaction = PreviewTransactions.debit(
            description: "Whole Foods Market",
            amountMinorUnits: 6543
        )
        let view = TransactionRowView(transaction: transaction)
        verifyComponentSnapshots(
            view,
            size: CGSize(width: 390, height: 60),
            record: record
        )
    }

    func test_transaction_row_credit() {
        let transaction = PreviewTransactions.credit(
            description: "Salary Deposit",
            amountMinorUnits: 500_000
        )
        let view = TransactionRowView(transaction: transaction)
        verifyComponentSnapshots(
            view,
            size: CGSize(width: 390, height: 60),
            record: record
        )
    }
}

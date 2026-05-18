import FinanceCore
@testable import FinanceOSMac
import FinanceTesting
import SnapshotTesting
import SwiftUI
import XCTest

final class TransactionDetailViewSnapshotTests: SnapshotTestable {
    override var record: Bool {
        true
    }

    func test_transaction_detail_debit() {
        let row = TransactionRow(
            id: UUID(),
            title: "Whole Foods Market",
            subtitle: "Chase Checking · USD",
            amountText: "$65.43",
            transactionType: .debit,
            postedAt: SnapshotConfiguration.referenceDate
        )
        let view = TransactionDetailView(row: row)
        verifyComponentSnapshots(view, size: CGSize(width: 480, height: 480))
    }

    func test_transaction_detail_credit() {
        let row = TransactionRow(
            id: UUID(),
            title: "Salary Deposit",
            subtitle: "Chase Checking · USD",
            amountText: "$5,000.00",
            transactionType: .credit,
            postedAt: SnapshotConfiguration.referenceDate
        )
        let view = TransactionDetailView(row: row)
        verifyComponentSnapshots(view, size: CGSize(width: 480, height: 480))
    }
}

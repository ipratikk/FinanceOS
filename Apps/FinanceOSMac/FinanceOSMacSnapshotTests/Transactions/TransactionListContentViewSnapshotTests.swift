import FinanceCore
@testable import FinanceOSMac
import FinanceTesting
import SnapshotTesting
import SwiftUI
import XCTest

final class TransactionListContentViewSnapshotTests: SnapshotTestable {
    override var record: Bool {
        false
    }

    func test_transaction_list_content() {
        let rows = PreviewTransactions.samples.map { txn in
            TransactionRow(
                id: txn.id,
                title: txn.description,
                subtitle: "Checking · USD",
                amountText: String(format: "$%.2f", Double(txn.amountMinorUnits) / 100),
                transactionType: txn.transactionType,
                postedAt: txn.postedAt
            )
        }
        let section = TransactionSection(
            id: "2025-05-01",
            title: "THURSDAY, MAY 1",
            date: Date(timeIntervalSince1970: 1_746_057_600),
            rows: rows,
            netAmountMinorUnits: 0
        )
        let view = TransactionListContentView(sections: [section], listState: TransactionListState())
        verifySnapshots(view)
    }
}

import FinanceCore
@testable import FinanceOSMac
import FinanceTesting
import SnapshotTesting
import SwiftUI
import XCTest

final class TransactionsViewSnapshotTests: SnapshotTestable {
    override var record: Bool {
        true
    }

    func test_transactions_view() {
        let transactionRepo = MockTransactionRepository()
        let ledgerRepo = MockLedgerRepository()
        let viewModel = TransactionsViewModel(
            transactionRepository: transactionRepo,
            ledgerRepository: ledgerRepo
        )
        viewModel.transactionRows = PreviewTransactions.samples.map { txn in
            TransactionRow(
                id: txn.id,
                title: txn.description,
                subtitle: "Checking · USD",
                amountText: String(format: "$%.2f", Double(txn.amountMinorUnits) / 100),
                transactionType: txn.transactionType,
                postedAt: txn.postedAt
            )
        }

        let view = TransactionsView(viewModel: viewModel)
        verifySnapshots(view)
    }
}

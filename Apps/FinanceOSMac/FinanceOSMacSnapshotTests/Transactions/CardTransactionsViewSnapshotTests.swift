import FinanceCore
@testable import FinanceOSMac
import FinanceTesting
import SnapshotTesting
import SwiftUI
import XCTest

final class CardTransactionsViewSnapshotTests: SnapshotTestable {
    override var record: Bool {
        false
    }

    func test_card_transactions_view() {
        let transactionRepo = MockTransactionRepository()
        let viewModel = CardTransactionsViewModel(transactionRepository: transactionRepo)
        viewModel.transactionRows = PreviewTransactions.samples.map { txn in
            TransactionRow(
                id: txn.id,
                title: txn.description,
                subtitle: "Amex Premium · USD",
                amountText: String(format: "$%.2f", Double(txn.amountMinorUnits) / 100),
                transactionType: txn.transactionType,
                postedAt: txn.postedAt
            )
        }

        let view = CardTransactionsView(
            ledger: PreviewLedgers.creditCard(),
            viewModel: viewModel
        )
        verifySnapshots(view)
    }
}

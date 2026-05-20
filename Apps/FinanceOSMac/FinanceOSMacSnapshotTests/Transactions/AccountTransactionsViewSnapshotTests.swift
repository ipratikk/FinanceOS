import FinanceCore
@testable import FinanceOSMac
import FinanceTesting
import SnapshotTesting
import SwiftUI
import XCTest

final class AccountTransactionsViewSnapshotTests: SnapshotTestable {
    override var record: Bool {
        true
    }

    func test_account_transactions_view() {
        let transactionRepo = MockTransactionRepository()
        let ledgerRepo = MockLedgerRepository()
        let viewModel = AccountTransactionsViewModel(
            transactionRepository: transactionRepo,
            ledgerRepository: ledgerRepo,
            bankRepository: MockBankRepository()
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

        let view = AccountTransactionsView(
            ledger: PreviewLedgers.checking(),
            viewModel: viewModel
        )
        verifySnapshots(view)
    }
}

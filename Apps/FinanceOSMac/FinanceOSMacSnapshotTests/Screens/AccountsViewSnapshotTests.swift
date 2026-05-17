import FinanceCore
@testable import FinanceOSMac
import FinanceTesting
import SnapshotTesting
import SwiftUI
import XCTest

final class AccountsViewSnapshotTests: SnapshotTestable {
    override var record: Bool {
        false
    }

    func test_accounts_view() {
        let ledgerRepo = MockLedgerRepository()
        let bankRepo = MockBankRepository()
        let transactionRepo = MockTransactionRepository()
        let viewModel = AccountsViewModel(
            ledgerRepository: ledgerRepo,
            bankRepository: bankRepo,
            transactionRepository: transactionRepo
        )
        viewModel.accounts = PreviewLedgers.all.filter { $0.kind == .bankAccount }
        viewModel.banks = PreviewBanks.all

        let view = AccountsView(
            viewModel: viewModel,
            transactionRepository: transactionRepo,
            ledgerRepository: ledgerRepo
        )
        verifySnapshots(view)
    }
}

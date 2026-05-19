import FinanceCore
@testable import FinanceOSMac
import FinanceTesting
import SnapshotTesting
import SwiftUI
import XCTest

final class BanksViewSnapshotTests: SnapshotTestable {
    override var record: Bool {
        false
    }

    func test_banks_view() {
        let bankRepo = MockBankRepository()
        let ledgerRepo = MockLedgerRepository()
        let viewModel = BanksViewModel(repository: bankRepo, ledgerRepository: ledgerRepo)
        viewModel.banks = PreviewBanks.all

        let view = BanksView(viewModel: viewModel)
        verifySnapshots(view)
    }
}

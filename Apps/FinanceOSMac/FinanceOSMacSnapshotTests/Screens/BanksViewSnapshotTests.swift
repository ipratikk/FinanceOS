import FinanceCore
@testable import FinanceOSMac
import FinanceTesting
import SnapshotTesting
import SwiftUI
import XCTest

final class BanksViewSnapshotTests: SnapshotTestable {
    override var record: Bool {
        true
    }

    func test_banks_view() {
        let bankRepo = MockBankRepository()
        let viewModel = BanksViewModel(repository: bankRepo)
        viewModel.banks = PreviewBanks.all

        let view = BanksView(viewModel: viewModel)
        verifySnapshots(view)
    }
}

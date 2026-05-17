import FinanceCore
@testable import FinanceOSMac
import FinanceTesting
import SnapshotTesting
import SwiftUI
import XCTest

final class BankEditViewSnapshotTests: SnapshotTestable {
    override var record: Bool {
        false
    }

    func test_bank_edit_view() {
        let bankRepo = MockBankRepository()
        let context = BankEditContext(repository: bankRepo)
        let view = BankEditView(bank: PreviewBanks.chase(), context: context)
        verifySnapshots(view)
    }
}

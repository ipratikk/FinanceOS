import FinanceCore
@testable import FinanceOSMac
import FinanceTesting
import SnapshotTesting
import SwiftUI
import XCTest

final class AccountEditViewSnapshotTests: SnapshotTestable {
    override var record: Bool {
        false
    }

    func test_account_edit_create() {
        let ledgerRepo = MockLedgerRepository()
        let context = AccountEditContext(repository: ledgerRepo, banks: PreviewBanks.all)
        let view = AccountEditView(account: PreviewLedgers.checking(), context: context)
        verifySnapshots(view)
    }
}

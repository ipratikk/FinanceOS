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
        let view = CardEditView(mode: .edit(PreviewLedgers.checking()))
        verifySnapshots(view)
    }
}

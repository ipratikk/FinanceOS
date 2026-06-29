import FinanceCore
@testable import FinanceOSMac
import FinanceTesting
import SnapshotTesting
import SwiftUI
import XCTest

final class CardEditViewSnapshotTests: SnapshotTestable {
    override var record: Bool {
        false
    }

    func test_card_edit_view() {
        let view = CardEditView(mode: .edit(PreviewLedgers.creditCard()))
        verifySnapshots(view)
    }
}

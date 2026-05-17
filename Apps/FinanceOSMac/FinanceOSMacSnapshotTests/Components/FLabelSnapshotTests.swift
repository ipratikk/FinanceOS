@testable import FinanceOSMac
import FinanceTesting
import FinanceUI
import SnapshotTesting
import SwiftUI
import XCTest

final class FLabelSnapshotTests: SnapshotTestable {
    override var record: Bool {
        false
    }

    func test_label_basic() {
        let view = FLabel("Section Title")
        verifyComponentSnapshots(view, size: CGSize(width: 400, height: 30))
    }

    func test_label_with_icon() {
        let view = FLabel("Bank Account", icon: "building.columns")
        verifyComponentSnapshots(view, size: CGSize(width: 400, height: 30))
    }
}

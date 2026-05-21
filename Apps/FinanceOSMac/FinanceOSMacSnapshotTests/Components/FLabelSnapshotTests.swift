@testable import FinanceOSMac
import FinanceTesting
import FinanceUI
import SnapshotTesting
import SwiftUI
import XCTest

final class FLabelSnapshotTests: SnapshotTestable {
    override var record: Bool { false }

    func test_label_basic() {
        let view = FDSLabel("Section Title")
        verifyComponentSnapshots(view, size: CGSize(width: 400, height: 30))
    }

    func test_label_with_icon() {
        let view = HStack(spacing: 4) {
            Image(systemName: "building.columns")
            FDSLabel("Bank Account")
        }
        verifyComponentSnapshots(view, size: CGSize(width: 400, height: 30))
    }
}

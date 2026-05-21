@testable import FinanceOSMac
import FinanceTesting
import FinanceUI
import SnapshotTesting
import SwiftUI
import XCTest

final class FDSLabelSnapshotTests: SnapshotTestable {
    override var record: Bool { false }

    func test_label_display_large() {
        let view = FDSLabel("$5,234.56", style: .displayLarge)
        verifyComponentSnapshots(view, size: CGSize(width: 400, height: 80))
    }

    func test_label_display_medium() {
        let view = FDSLabel("Dashboard", style: .displayMedium)
        verifyComponentSnapshots(view, size: CGSize(width: 400, height: 60))
    }

    func test_label_body_medium() {
        let view = FDSLabel("Recent transactions", style: .bodyMedium)
        verifyComponentSnapshots(view, size: CGSize(width: 400, height: 30))
    }

    func test_label_caption() {
        let view = FDSLabel("This Month", style: .caption)
        verifyComponentSnapshots(view, size: CGSize(width: 400, height: 24))
    }
}

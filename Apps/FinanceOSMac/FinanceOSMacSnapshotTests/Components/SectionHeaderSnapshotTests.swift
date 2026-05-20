import FinanceCore
@testable import FinanceOSMac
import FinanceTesting
import FinanceUI
import SnapshotTesting
import SwiftUI
import XCTest

final class SectionHeaderSnapshotTests: SnapshotTestable {
    override var record: Bool {
        false
    }

    func test_section_header_basic() {
        let view = FDSSectionHeader("Recent Activity")
        verifyComponentSnapshots(view, size: CGSize(width: 400, height: 60))
    }

    func test_section_header_with_subtitle() {
        let view = FDSSectionHeader("Recent Activity", subtitle: "Last 30 days")
        verifyComponentSnapshots(view, size: CGSize(width: 400, height: 80))
    }

    func test_section_header_with_action() {
        let view = FDSSectionHeader("Recent Activity", actionLabel: "View All", action: {})
        verifyComponentSnapshots(view, size: CGSize(width: 400, height: 60))
    }
}

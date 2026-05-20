import FinanceCore
@testable import FinanceOSMac
import FinanceTesting
import FinanceUI
import SnapshotTesting
import SwiftUI
import XCTest

final class SectionHeaderSnapshotTests: SnapshotTestable {
    override var record: Bool {
        true
    }

    func test_section_header_basic() {
        let view = SectionHeader("Recent Activity")
        verifyComponentSnapshots(view, size: CGSize(width: 400, height: 60))
    }

    func test_section_header_with_subtitle() {
        let view = SectionHeader("Recent Activity", subtitle: "Last 30 days")
        verifyComponentSnapshots(view, size: CGSize(width: 400, height: 80))
    }

    func test_section_header_with_action() {
        let view = SectionHeader("Recent Activity", action: {}, actionLabel: "View All")
        verifyComponentSnapshots(view, size: CGSize(width: 400, height: 60))
    }
}

import FinanceCore
@testable import FinanceOSMac
import FinanceUI
import SnapshotTesting
import SwiftUI
import XCTest

final class FDSSectionHeaderComponentSnapshotTests: SnapshotTestable {
    override var record: Bool { false }

    func test_section_header_title_only() {
        let view = FDSSectionHeader("Recent Activity")
        verifyFDSComponent(view, size: CGSize(width: 480, height: 72))
    }

    func test_section_header_with_subtitle() {
        let view = FDSSectionHeader("Recent Activity", subtitle: "Last 6 transactions")
        verifyFDSComponent(view, size: CGSize(width: 480, height: 80))
    }

    func test_section_header_with_action() {
        let view = FDSSectionHeader(
            "Recent Activity",
            subtitle: "Last 6 transactions",
            actionLabel: "View All",
            action: {}
        )
        verifyFDSComponent(view, size: CGSize(width: 480, height: 80))
    }

    func test_section_header_sidebar_header() {
        let view = FDSSidebarSectionHeader("OVERVIEW")
        verifyFDSComponent(view, size: CGSize(width: 240, height: 56))
    }
}

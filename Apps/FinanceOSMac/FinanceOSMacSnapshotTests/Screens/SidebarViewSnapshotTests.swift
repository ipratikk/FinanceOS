@testable import FinanceOSMac
import FinanceTesting
import SnapshotTesting
import SwiftUI
import XCTest

final class SidebarViewSnapshotTests: SnapshotTestable {
    override var record: Bool { false }

    func test_sidebar_initial() {
        verifySnapshots(SidebarView())
    }
}

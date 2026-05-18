@testable import FinanceOSMac
import FinanceTesting
import FinanceUI
import SnapshotTesting
import SwiftUI
import XCTest

final class FBadgeSnapshotTests: SnapshotTestable {
    override var record: Bool {
        true
    }

    func test_badge_default() {
        let view = FBadge("Active")
        verifyComponentSnapshots(view, size: CGSize(width: 200, height: 40))
    }

    func test_badge_with_icon() {
        let view = FBadge("Verified", color: .green, icon: "checkmark.circle")
        verifyComponentSnapshots(view, size: CGSize(width: 200, height: 40))
    }

    func test_badge_red() {
        let view = FBadge("Failed", color: .red)
        verifyComponentSnapshots(view, size: CGSize(width: 200, height: 40))
    }
}

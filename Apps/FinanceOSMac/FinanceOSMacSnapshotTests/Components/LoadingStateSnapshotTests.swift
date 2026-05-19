import FinanceCore
@testable import FinanceOSMac
import FinanceTesting
import FinanceUI
import SnapshotTesting
import SwiftUI
import XCTest

final class LoadingStateSnapshotTests: SnapshotTestable {
    override var record: Bool {
        false
    }

    func test_loading_skeleton_view() {
        let view = LoadingSkeletonView()
        verifyComponentSnapshots(view, size: CGSize(width: 390, height: 200))
    }
}

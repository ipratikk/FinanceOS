import FinanceCore
@testable import FinanceOSMac
import FinanceTesting
import SnapshotTesting
import SwiftUI
import XCTest

final class LoadingStateSnapshotTests: XCTestCase {
    let record = false

    func test_loading_skeleton_view() {
        let view = LoadingSkeletonView()
        verifyComponentSnapshots(
            view,
            size: CGSize(width: 390, height: 200),
            record: record
        )
    }
}

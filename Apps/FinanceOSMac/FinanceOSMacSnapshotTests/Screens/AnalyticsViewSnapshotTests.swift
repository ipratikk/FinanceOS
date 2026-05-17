@testable import FinanceOSMac
import FinanceTesting
import SnapshotTesting
import SwiftUI
import XCTest

final class AnalyticsViewSnapshotTests: XCTestCase {
    let record = false

    func test_analytics_view() {
        let view = AnalyticsView()
        verifySnapshots(view, device: .iPhone16Pro, record: record)
    }

    func test_analytics_all_devices() {
        let view = AnalyticsView()
        verifySnapshotsAcrossDevices(
            view,
            devices: .mobileDevices,
            record: record
        )
    }
}

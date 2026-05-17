@testable import FinanceOSMac
import FinanceTesting
import SnapshotTesting
import SwiftUI
import XCTest

final class DashboardViewSnapshotTests: XCTestCase {
    let record = false

    func test_dashboard_initial() {
        let view = DashboardView()
        verifySnapshots(view, device: .iPhone16Pro, record: record)
    }

    func test_dashboard_all_devices() {
        let view = DashboardView()
        verifySnapshotsAcrossDevices(
            view,
            devices: .mobileDevices,
            record: record
        )
    }
}

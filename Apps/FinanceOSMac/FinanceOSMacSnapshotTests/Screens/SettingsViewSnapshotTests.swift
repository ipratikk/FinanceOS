@testable import FinanceOSMac
import FinanceTesting
import SnapshotTesting
import SwiftUI
import XCTest

final class SettingsViewSnapshotTests: XCTestCase {
    let record = false

    func test_settings_view() {
        let view = SettingsView()
        verifySnapshots(view, device: .iPhone16Pro, record: record)
    }

    func test_settings_all_devices() {
        let view = SettingsView()
        verifySnapshotsAcrossDevices(
            view,
            devices: .mobileDevices,
            record: record
        )
    }
}

@testable import FinanceOSMac
import FinanceTesting
import SnapshotTesting
import SwiftUI
import XCTest

final class BanksViewSnapshotTests: XCTestCase {
    let record = false

    func test_banks_view() {
        let view = BanksView()
        verifySnapshots(view, device: .iPhone16Pro, record: record)
    }

    func test_banks_all_devices() {
        let view = BanksView()
        verifySnapshotsAcrossDevices(
            view,
            devices: .mobileDevices,
            record: record
        )
    }
}

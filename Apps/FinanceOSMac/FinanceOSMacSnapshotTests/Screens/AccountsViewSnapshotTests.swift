@testable import FinanceOSMac
import FinanceTesting
import SnapshotTesting
import SwiftUI
import XCTest

final class AccountsViewSnapshotTests: XCTestCase {
    let record = false

    func test_accounts_view() {
        let view = AccountsView()
        verifySnapshots(view, device: .iPhone16Pro, record: record)
    }

    func test_accounts_view_all_devices() {
        let view = AccountsView()
        verifySnapshotsAcrossDevices(
            view,
            devices: .mobileDevices,
            record: record
        )
    }
}

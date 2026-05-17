@testable import FinanceOSMac
import FinanceTesting
import SnapshotTesting
import SwiftUI
import XCTest

final class TransactionsViewSnapshotTests: XCTestCase {
    let record = false

    func test_transactions_view() {
        let view = TransactionsView()
        verifySnapshots(view, device: .iPhone16Pro, record: record)
    }

    func test_transactions_all_devices() {
        let view = TransactionsView()
        verifySnapshotsAcrossDevices(
            view,
            devices: .mobileDevices,
            record: record
        )
    }
}

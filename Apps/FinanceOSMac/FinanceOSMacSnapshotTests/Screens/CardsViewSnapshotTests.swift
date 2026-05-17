@testable import FinanceOSMac
import FinanceTesting
import SnapshotTesting
import SwiftUI
import XCTest

final class CardsViewSnapshotTests: XCTestCase {
    let record = false

    func test_cards_view() {
        let view = CardsView()
        verifySnapshots(view, device: .iPhone16Pro, record: record)
    }

    func test_cards_all_devices() {
        let view = CardsView()
        verifySnapshotsAcrossDevices(
            view,
            devices: .mobileDevices,
            record: record
        )
    }
}

@testable import FinanceOSMac
import FinanceTesting
import SnapshotTesting
import SwiftUI
import XCTest

final class SettingsViewSnapshotTests: SnapshotTestable {
    override var record: Bool {
        true
    }

    func test_settings_view() {
        verifySnapshots(SettingsView())
    }
}

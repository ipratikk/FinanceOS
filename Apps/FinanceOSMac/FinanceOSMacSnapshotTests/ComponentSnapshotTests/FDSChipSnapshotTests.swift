import FinanceCore
@testable import FinanceOSMac
import FinanceUI
import SnapshotTesting
import SwiftUI
import XCTest

final class FDSChipSnapshotTests: SnapshotTestable {
    override var record: Bool { false }

    func test_chip_active_accent() {
        let view = FDSChip("All", isActive: true, tone: .accent) {}
        verifyFDSComponent(view, size: CGSize(width: 200, height: 60))
    }

    func test_chip_inactive_accent() {
        let view = FDSChip("All", isActive: false, tone: .accent) {}
        verifyFDSComponent(view, size: CGSize(width: 200, height: 60))
    }

    func test_chip_active_debit() {
        let view = FDSChip("Debit", isActive: true, tone: .debit) {}
        verifyFDSComponent(view, size: CGSize(width: 200, height: 60))
    }

    func test_chip_active_credit() {
        let view = FDSChip("Credit", isActive: true, tone: .credit) {}
        verifyFDSComponent(view, size: CGSize(width: 200, height: 60))
    }

    func test_chip_disabled() {
        let view = FDSChip("Disabled", isActive: false, isEnabled: false) {}
        verifyFDSComponent(view, size: CGSize(width: 200, height: 60))
    }

    func test_chip_filter_row() {
        let view = HStack(spacing: 8) {
            FDSChip("All", isActive: true) {}
            FDSChip("Debit", isActive: false, tone: .debit) {}
            FDSChip("Credit", isActive: false, tone: .credit) {}
        }
        verifyFDSComponent(view, size: CGSize(width: 360, height: 64))
    }
}

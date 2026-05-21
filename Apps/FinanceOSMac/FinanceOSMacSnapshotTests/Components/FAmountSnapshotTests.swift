@testable import FinanceOSMac
import FinanceTesting
import FinanceUI
import SnapshotTesting
import SwiftUI
import XCTest

final class FAmountSnapshotTests: SnapshotTestable {
    override var record: Bool {
        false
    }

    func test_amount_debit_small() {
        let view = FAmount(6543, currency: "USD", isDebit: true, size: .small)
        verifyComponentSnapshots(view, size: CGSize(width: 200, height: 30))
    }

    func test_amount_credit_medium() {
        let view = FAmount(500_000, currency: "USD", isDebit: false, size: .medium)
        verifyComponentSnapshots(view, size: CGSize(width: 240, height: 40))
    }

    func test_amount_large() {
        let view = FAmount(265_433, currency: "USD", isDebit: false, size: .large)
        verifyComponentSnapshots(view, size: CGSize(width: 320, height: 60))
    }
}

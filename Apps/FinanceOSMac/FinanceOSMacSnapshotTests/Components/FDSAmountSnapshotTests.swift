@testable import FinanceOSMac
import FinanceTesting
import FinanceUI
import SnapshotTesting
import SwiftUI
import XCTest

final class FDSAmountSnapshotTests: SnapshotTestable {
    override var record: Bool {
        true
    }

    func test_amount_debit() {
        let view = FDSAmount("$65.43", type: .debit)
        verifyComponentSnapshots(view, size: CGSize(width: 240, height: 40))
    }

    func test_amount_credit() {
        let view = FDSAmount("$5,000.00", type: .credit)
        verifyComponentSnapshots(view, size: CGSize(width: 240, height: 40))
    }

    func test_amount_small_debit() {
        let view = FDSAmount("$2,654.33", type: .debit, size: .small)
        verifyComponentSnapshots(view, size: CGSize(width: 320, height: 40))
    }
}

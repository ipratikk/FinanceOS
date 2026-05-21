import FinanceCore
@testable import FinanceOSMac
import FinanceTesting
import FinanceUI
import SnapshotTesting
import SwiftUI
import XCTest

final class FinanceCardSnapshotTests: SnapshotTestable {
    override var record: Bool { false }

    func test_finance_card_basic() {
        let view = FDSCard {
            VStack(alignment: .leading, spacing: 8) {
                Text("Chase Checking")
                    .font(.headline)
                Text("$5,234.56")
                    .font(.title)
                    .bold()
            }
        }
        verifyComponentSnapshots(view, size: CGSize(width: 320, height: 140))
    }
}

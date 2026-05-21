import FinanceCore
@testable import FinanceOSMac
import FinanceTesting
import FinanceUI
import SnapshotTesting
import SwiftUI
import XCTest

final class InsightCardSnapshotTests: SnapshotTestable {
    override var record: Bool { false }

    func test_insight_card() {
        let view = InsightCard("Net Balance", value: "$2,654.33") {
            Text("Up 12.5% from last month")
                .font(.caption)
                .foregroundColor(.green)
        }
        verifyComponentSnapshots(view, size: CGSize(width: 320, height: 140))
    }
}

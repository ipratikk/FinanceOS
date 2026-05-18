import FinanceCore
@testable import FinanceOSMac
import FinanceTesting
import SnapshotTesting
import SwiftUI
import XCTest

final class ChartContainerSnapshotTests: SnapshotTestable {
    override var record: Bool {
        true
    }

    func test_chart_container() {
        let view = ChartContainer("6-Month Trend") {
            Rectangle()
                .fill(Color.blue.opacity(0.3))
                .frame(height: 200)
        }
        verifyComponentSnapshots(view, size: CGSize(width: 600, height: 280))
    }
}

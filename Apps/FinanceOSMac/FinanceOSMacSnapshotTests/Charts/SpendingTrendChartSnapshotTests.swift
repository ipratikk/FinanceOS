import FinanceCore
@testable import FinanceOSMac
import FinanceTesting
import SnapshotTesting
import SwiftUI
import XCTest

final class SpendingTrendChartSnapshotTests: SnapshotTestable {
    override var record: Bool {
        false
    }

    func test_spending_trend_chart() {
        let view = SpendingTrendChart(monthlySummaries: PreviewSpendingData.monthlySummaries)
        verifyComponentSnapshots(view, size: CGSize(width: 800, height: 400))
    }

    func test_spending_trend_chart_empty() {
        let view = SpendingTrendChart(monthlySummaries: [])
        verifyComponentSnapshots(view, size: CGSize(width: 800, height: 400))
    }
}

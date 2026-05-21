@testable import FinanceOSMac
import FinanceTesting
import SnapshotTesting
import SwiftUI
import XCTest

final class TopMerchantsChartSnapshotTests: SnapshotTestable {
    override var record: Bool { false }

    func test_top_merchants_chart() {
        let view = TopMerchantsChart(merchants: [
            (name: "Whole Foods Market", amount: 654.30),
            (name: "Target", amount: 1456.70),
            (name: "Shell Gas", amount: 421.50),
            (name: "Starbucks", amount: 62.50),
            (name: "Amazon", amount: 875.00)
        ])
        verifyComponentSnapshots(view, size: CGSize(width: 800, height: 400))
    }

    func test_top_merchants_chart_empty() {
        let view = TopMerchantsChart(merchants: [])
        verifyComponentSnapshots(view, size: CGSize(width: 800, height: 400))
    }
}

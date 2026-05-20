import FinanceCore
@testable import FinanceOSMac
import FinanceTesting
import FinanceUI
import SnapshotTesting
import SwiftUI
import XCTest

final class MetricCardSnapshotTests: SnapshotTestable {
    override var record: Bool {
        true
    }

    func test_metric_card_basic() {
        let view = MetricCard("Spent", value: "$2,345.67")
        verifyComponentSnapshots(view, size: CGSize(width: 240, height: 100))
    }

    func test_metric_card_with_delta_positive() {
        let view = MetricCard(
            "Income",
            value: "$5,000.00",
            delta: MetricCard.Delta(change: 12.5, period: "vs last month")
        )
        verifyComponentSnapshots(view, size: CGSize(width: 240, height: 120))
    }

    func test_metric_card_with_delta_negative() {
        let view = MetricCard(
            "Spending",
            value: "$3,200.00",
            delta: MetricCard.Delta(change: -8.3, period: "vs last month")
        )
        verifyComponentSnapshots(view, size: CGSize(width: 240, height: 120))
    }

    func test_metric_card_with_icon() {
        let view = MetricCard("Cards", value: "3", icon: "creditcard")
        verifyComponentSnapshots(view, size: CGSize(width: 240, height: 100))
    }
}

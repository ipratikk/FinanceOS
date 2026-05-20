import FinanceCore
@testable import FinanceOSMac
import FinanceTesting
import SnapshotTesting
import SwiftUI
import XCTest

final class AnalyticsViewSnapshotTests: SnapshotTestable {
    override var record: Bool {
        true
    }

    func test_analytics_view() {
        let spending = MockSpendingService()
        let transactionRepo = MockTransactionRepository()
        let viewModel = AnalyticsViewModel(
            spendingService: spending,
            transactionRepository: transactionRepo
        )
        viewModel.monthlySummaries = PreviewSpendingData.monthlySummaries
        viewModel.topMerchants = [
            ("Whole Foods Market", 6543),
            ("Target", 14567),
            ("Shell Gas", 4215),
            ("Starbucks", 625)
        ]

        let view = AnalyticsView(viewModel: viewModel)
        verifySnapshots(view)
    }
}

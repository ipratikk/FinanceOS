import FinanceCore
@testable import FinanceOSMac
import FinanceTesting
import SnapshotTesting
import SwiftUI
import XCTest

final class DashboardViewSnapshotTests: SnapshotTestable {
    override var record: Bool {
        true
    }

    func test_dashboard_initial() {
        let spending = MockSpendingService()
        let transactionRepo = MockTransactionRepository()
        let viewModel = DashboardViewModel(
            spendingService: spending,
            transactionRepository: transactionRepo
        )
        viewModel.currentTotals = PreviewSpendingData.currentTotals
        viewModel.monthlySummaries = PreviewSpendingData.monthlySummaries
        viewModel.recentTransactions = PreviewTransactions.samples

        let view = DashboardView(viewModel: viewModel)
        verifySnapshots(view)
    }
}

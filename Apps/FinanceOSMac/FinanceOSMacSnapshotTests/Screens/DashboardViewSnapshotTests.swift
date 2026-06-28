import FinanceCore
@testable import FinanceOSMac
import FinanceTesting
import SnapshotTesting
import SwiftUI
import XCTest

final class DashboardViewSnapshotTests: SnapshotTestable {
    override var record: Bool {
        false
    }

    func test_dashboard_initial() {
        let graphQLClient = ApolloGraphQLClient()
        let viewModel = DashboardViewModel(
            graphQLClient: graphQLClient,
            exportService: ExportService()
        )
        viewModel.currentTotals = PreviewSpendingData.currentTotals
        viewModel.monthlySummaries = PreviewSpendingData.monthlySummaries
        viewModel.recentTransactions = PreviewTransactions.samples

        let insightsViewModel = InsightNarrativeViewModel(graphQLClient: graphQLClient)
        let view = DashboardView(viewModel: viewModel, insightsViewModel: insightsViewModel)
        verifySnapshots(view)
    }
}

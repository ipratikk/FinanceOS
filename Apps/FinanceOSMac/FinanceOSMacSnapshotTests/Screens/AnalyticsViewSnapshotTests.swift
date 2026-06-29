import FinanceCore
@testable import FinanceOSMac
import FinanceTesting
import SnapshotTesting
import SwiftUI
import XCTest

final class AnalyticsViewSnapshotTests: SnapshotTestable {
    override var record: Bool {
        false
    }

    func test_analytics_view() {
        let viewModel = AnalyticsViewModel(
            graphQLClient: ApolloGraphQLClient(),
            aggregator: AnalyticsAggregatorService()
        )
        viewModel.monthlySummaries = PreviewSpendingData.monthlySummaries

        let view = AnalyticsView(viewModel: viewModel)
        verifySnapshots(view)
    }
}

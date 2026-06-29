import Charts
import FinanceCore
import FinanceUI
import SwiftUI

struct AnalyticsView: View {
    @State private var viewModel: AnalyticsViewModel

    init(viewModel: AnalyticsViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                pageHeader
                topRow
                middleRow
            }
            .padding(.horizontal, AppSpacing.xl)
            .padding(.vertical, AppSpacing.xl)
        }
        .background(AppColors.base)
        .task { await viewModel.load() }
    }

    private var pageHeader: some View {
        FDSLabel("Analytics")
            .font(AppTypography.displaySmall)
            .foregroundStyle(AppColors.Text.primary)
    }

    private var topRow: some View {
        HStack(alignment: .top, spacing: AppSpacing.md) {
            SpendingTrendCard(
                summaries: viewModel.monthlySummaries,
                totalOutflowText: viewModel.totalOutflowText,
                periodLabel: viewModel.periodLabel,
                outflowChange: viewModel.outflowChange
            )
            CategoriesCard(items: viewModel.categorySpend)
                .frame(width: 280)
        }
    }

    private var middleRow: some View {
        HStack(alignment: .top, spacing: AppSpacing.md) {
            TopMerchantsCard(merchants: viewModel.merchantSummaries)
            SmartInsightsCard(insights: viewModel.insights)
                .frame(width: 280)
        }
    }
}

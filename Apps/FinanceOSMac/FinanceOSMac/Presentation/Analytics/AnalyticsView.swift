import Charts
import FinanceCore
import FinanceIntelligence
import FinanceUI
import SwiftUI

struct AnalyticsView: View {
    @State private var viewModel: AnalyticsViewModel?
    @Environment(\.transactionIntelligence) private var intelligence

    var body: some View {
        Group {
            if let viewModel {
                content(viewModel)
            } else {
                loadingState
            }
        }
        .task {
            if viewModel == nil {
                let container = AppContainer.shared
                viewModel = AnalyticsViewModel(
                    spendingService: container.spendingService,
                    transactionRepository: container.transactionRepository,
                    intelligenceService: intelligence
                )
            }
        }
    }

    private func content(_ vm: AnalyticsViewModel) -> some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                pageHeader
                topRow(vm)
                middleRow(vm)
                RecentFluctuationsCard(transactions: vm.recentFluctuations)
            }
            .padding(.horizontal, AppSpacing.xl)
            .padding(.vertical, AppSpacing.xl)
        }
        .background(AppColors.base)
        .task { await vm.load() }
    }

    private var loadingState: some View {
        VStack(spacing: AppSpacing.md) {
            ProgressView().controlSize(.small)
            FDSLabel("Loading…")
                .font(AppTypography.captionSmMedium)
                .foregroundStyle(AppColors.Text.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.base)
    }

    private var pageHeader: some View {
        FDSLabel("Analytics")
            .font(AppTypography.displaySmall)
            .foregroundStyle(AppColors.Text.primary)
    }

    private func topRow(_ vm: AnalyticsViewModel) -> some View {
        HStack(alignment: .top, spacing: AppSpacing.md) {
            SpendingTrendCard(
                summaries: vm.monthlySummaries,
                totalOutflow: vm.totalOutflow,
                outflowChange: vm.outflowChange
            )
            CategoriesCard(items: vm.categorySpend)
                .frame(width: 280)
        }
    }

    private func middleRow(_ vm: AnalyticsViewModel) -> some View {
        HStack(alignment: .top, spacing: AppSpacing.md) {
            TopMerchantsCard(merchants: vm.merchantSummaries)
            SmartInsightsCard(insights: vm.insights)
                .frame(width: 280)
        }
    }
}

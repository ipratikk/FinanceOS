import Charts
import FinanceCore
import FinanceUI
import SwiftUI

struct DashboardView: View {
    @State private var viewModel: DashboardViewModel
    @State private var insightsViewModel: InsightNarrativeViewModel
    @State var showOpeningBalanceSheet = false
    @Environment(AppNavigator.self) var navigator

    init(viewModel: DashboardViewModel, insightsViewModel: InsightNarrativeViewModel) {
        _viewModel = State(initialValue: viewModel)
        _insightsViewModel = State(initialValue: insightsViewModel)
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: AppSpacing.xxl) {
                netWorthHero(viewModel)

                if viewModel.effectiveTotals != nil {
                    metricsRow(viewModel)
                }

                narrativeInsightsSection

                recentActivityCard(viewModel)
            }
            .padding(AppSpacing.xxxl)
        }
        .background(AppColors.base)
        .task {
            await viewModel.load()
            await insightsViewModel.refreshIfNeeded()
        }
        .sheet(isPresented: $showOpeningBalanceSheet) {
            OpeningBalanceSheet(viewModel: viewModel)
        }
    }

    @ViewBuilder
    private var narrativeInsightsSection: some View {
        if insightsViewModel.isLoading {
            ProgressView()
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, AppSpacing.md)
        } else if !insightsViewModel.insights.isEmpty {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                FDSLabel("MONTHLY INSIGHTS")
                    .font(AppTypography.captionSmSemibold)
                    .tracking(0.8)
                    .foregroundStyle(AppColors.Text.tertiary)
                ForEach(insightsViewModel.insights) { item in
                    InsightNarrativeCard(text: item.text, severity: item.severity)
                }
            }
        }
    }
}

// Preview removed — inject DashboardViewModel from call site

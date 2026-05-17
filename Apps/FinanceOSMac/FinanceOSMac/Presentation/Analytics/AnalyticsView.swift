import Charts
import FinanceCore
import FinanceUI
import SwiftUI

struct AnalyticsView: View {
    @State private var viewModel: AnalyticsViewModel?
    @State private var isLoading = true

    private let appContainer = AppContainer.shared

    init() {}

    init(viewModel: AnalyticsViewModel) {
        _viewModel = State(initialValue: viewModel)
        _isLoading = State(initialValue: false)
    }

    var body: some View {
        if let viewModel {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    header

                    if !viewModel.monthlySummaries.isEmpty {
                        spendingTrendSection
                    }

                    if !viewModel.topMerchants.isEmpty {
                        topMerchantsSection
                    }

                    categoriesSection
                }
                .padding(AppSpacing.md)
            }
            .background(AppColors.base)
            .task {
                await viewModel.load()
                isLoading = false
            }
        } else {
            VStack {
                ProgressView("Loading Analytics...")
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(AppColors.base)
            .task {
                let analyticsViewModel = AnalyticsViewModel(
                    spendingService: appContainer.spendingService,
                    transactionRepository: appContainer.transactionRepository
                )
                viewModel = analyticsViewModel
            }
        }
    }

    var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            FDSLabel("Analytics", style: .headingLarge)

            FDSLabel("Spending insights & trends", style: .hint)
        }
    }

    var spendingTrendSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            FDSLabel("6-Month Spending Trend", style: .subheading)

            if let viewModel, !viewModel.monthlySummaries.isEmpty {
                Chart(viewModel.monthlySummaries, id: \.id) { item in
                    BarMark(
                        x: .value("Month", item.id, unit: .month),
                        y: .value("Debits", Double(item.totalDebit) / 100.0)
                    )
                    .foregroundStyle(AppColors.debit.opacity(0.8))
                    .position(by: .value("Type", "Debits"))

                    BarMark(
                        x: .value("Month", item.id, unit: .month),
                        y: .value("Credits", Double(item.totalCredit) / 100.0)
                    )
                    .foregroundStyle(AppColors.credit.opacity(0.8))
                    .position(by: .value("Type", "Credits"))
                }
                .frame(height: 200)
                .chartLegend(position: .bottom)
                .chartXAxis {
                    AxisMarks(format: .dateTime.month(.abbreviated))
                }
                .chartYAxis {
                    AxisMarks { _ in
                        AxisGridLine()
                            .foregroundStyle(AppColors.surface2)
                    }
                }
                .padding(AppSpacing.sm)
                .background(AppColors.surface2)
                .cornerRadius(AppRadius.md)
            }
        }
        .padding(AppSpacing.sm)
        .background(AppColors.surface)
        .cornerRadius(AppRadius.md)
    }

    var topMerchantsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            FDSLabel("Top Merchants", style: .subheading)

            if let viewModel {
                let merchants = viewModel.topMerchants.prefix(10).map { merchant, amount in
                    (name: merchant, amount: Double(amount) / 100.0)
                }
                TopMerchantsChart(merchants: Array(merchants))
            }
        }
        .padding(AppSpacing.sm)
        .background(AppColors.surface)
        .cornerRadius(AppRadius.md)
    }

    var categoriesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            FDSLabel("Categories", style: .subheading)

            VStack(alignment: .center, spacing: 8) {
                Image(systemName: "tag.circle.fill")
                    .font(.system(size: 40, weight: .thin))
                    .foregroundColor(AppColors.accent.opacity(0.3))

                VStack(spacing: 4) {
                    FDSLabel("Coming Soon", style: .monoAmount)

                    FDSLabel("Auto-categorization with smart detection", style: .hint)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(AppSpacing.xl)
            .background(AppColors.surface2)
            .cornerRadius(AppRadius.md)
        }
        .padding(AppSpacing.sm)
        .background(AppColors.surface)
        .cornerRadius(AppRadius.md)
    }
}

#Preview {
    AnalyticsView()
}

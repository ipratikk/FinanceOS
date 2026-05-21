import Charts
import FinanceCore
import FinanceUI
import SwiftUI

struct AnalyticsView: View {
    @State private var viewModel: AnalyticsViewModel?
    @State private var isLoading = true

    init() {}

    init(viewModel: AnalyticsViewModel) {
        _viewModel = State(initialValue: viewModel)
        _isLoading = State(initialValue: false)
    }

    var body: some View {
        if let viewModel {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    header

                    if !viewModel.monthlySummaries.isEmpty {
                        spendingTrendSection(viewModel)
                    }

                    if !viewModel.topMerchants.isEmpty {
                        topMerchantsSection(viewModel)
                    }

                    categoriesPlaceholder
                }
                .padding(.horizontal, 32)
                .padding(.vertical, 24)
            }
            .background(AppColors.base)
            .task {
                await viewModel.load()
                isLoading = false
            }
        } else {
            VStack(spacing: 12) {
                ProgressView().controlSize(.small)
                FDSLabel("Loading…")
                    .font(AppTypography.captionSmMedium)
                    .foregroundColor(AppColors.Text.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(AppColors.base)
            .task {
                let container = AppContainer.shared
                viewModel = AnalyticsViewModel(
                    spendingService: container.spendingService,
                    transactionRepository: container.transactionRepository
                )
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            FDSLabel("Analytics")
                .font(AppTypography.displaySmall)
                .foregroundColor(AppColors.Text.primary)
            FDSLabel("Spending trends and merchant insights")
                .font(AppTypography.captionLgMedium)
                .tracking(0.2)
                .foregroundColor(AppColors.Text.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func spendingTrendSection(_ viewModel: AnalyticsViewModel) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                FDSLabel("6-Month Trend")
                    .font(AppTypography.headingSmall)
                    .foregroundColor(AppColors.Text.primary)
                FDSLabel("Inflows vs outflows over time")
                    .font(AppTypography.captionLgMedium)
                    .foregroundColor(AppColors.Text.secondary)
            }

            FDSCard(cornerRadius: 12, padded: false) {
                Chart(viewModel.monthlySummaries, id: \.id) { item in
                    BarMark(
                        x: .value("Month", item.id, unit: .month),
                        y: .value("Outflows", Double(item.totalDebit) / 100.0)
                    )
                    .foregroundStyle(AppColors.debit.opacity(0.8))
                    .cornerRadius(AppRadius.xs)
                    .position(by: .value("Type", "Outflows"))

                    BarMark(
                        x: .value("Month", item.id, unit: .month),
                        y: .value("Inflows", Double(item.totalCredit) / 100.0)
                    )
                    .foregroundStyle(AppColors.credit.opacity(0.8))
                    .cornerRadius(AppRadius.xs)
                    .position(by: .value("Type", "Inflows"))
                }
                .frame(height: 240)
                .chartLegend(position: .bottom)
                .chartXAxis {
                    AxisMarks(format: .dateTime.month(.abbreviated))
                }
                .chartYAxis {
                    AxisMarks { _ in
                        AxisGridLine().foregroundStyle(AppColors.textPrimary.opacity(0.06))
                        AxisValueLabel()
                    }
                }
                .padding(AppSpacing.sm)
            }
        }
    }

    private func topMerchantsSection(_ viewModel: AnalyticsViewModel) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                FDSLabel("Top Merchants")
                    .font(AppTypography.headingSmall)
                    .foregroundColor(AppColors.Text.primary)
                FDSLabel("Highest outflow activity")
                    .font(AppTypography.captionLgMedium)
                    .foregroundColor(AppColors.Text.secondary)
            }

            FDSCard(cornerRadius: 12, padded: false) {
                let merchants = viewModel.topMerchants.prefix(10).map { name, amount in
                    (name: name, amount: Double(amount) / 100.0)
                }
                TopMerchantsChart(merchants: Array(merchants))
                    .frame(height: 240)
                    .padding(AppSpacing.sm)
            }
        }
    }

    private var categoriesPlaceholder: some View {
        VStack(alignment: .leading, spacing: 12) {
            FDSLabel("Categories")
                .font(AppTypography.headingSmall)
                .foregroundColor(AppColors.Text.primary)

            FDSCard(cornerRadius: 12, padded: false) {
                VStack(spacing: 12) {
                    Image(systemName: "tag.circle.fill")
                        .font(AppTypography.headingXLLight)
                        .foregroundColor(AppColors.Text.tertiary.opacity(0.4))
                        .symbolRenderingMode(.hierarchical)
                    VStack(spacing: 4) {
                        FDSLabel("Coming Soon")
                            .font(AppTypography.bodyMdSemibold)
                            .foregroundColor(AppColors.Text.primary)
                        FDSLabel("Auto-categorization with smart detection")
                            .font(AppTypography.captionLg)
                            .foregroundColor(AppColors.Text.secondary)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(AppSpacing.xl)
            }
        }
    }
}

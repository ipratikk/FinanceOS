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
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: AppSpacing.xl) {
                    header

                    if !viewModel.monthlySummaries.isEmpty {
                        spendingTrendSection(viewModel)
                    }

                    if !viewModel.topMerchants.isEmpty {
                        topMerchantsSection(viewModel)
                    }

                    categoriesPlaceholder
                }
                .padding(.horizontal, AppSpacing.xl)
                .padding(.vertical, AppSpacing.xl)
            }
            .background(AppColors.base)
            .task {
                await viewModel.load()
                isLoading = false
            }
        } else {
            VStack(spacing: AppSpacing.md) {
                ProgressView().controlSize(.small)
                Text("Loading…")
                    .font(AppTypography.captionSm)
                    .foregroundStyle(.tertiary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(AppColors.base)
            .task {
                viewModel = AnalyticsViewModel(
                    spendingService: appContainer.spendingService,
                    transactionRepository: appContainer.transactionRepository
                )
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text("Analytics")
                .font(AppTypography.headingLg)
                .foregroundStyle(.primary)
            Text("Spending trends and merchant insights")
                .font(AppTypography.labelMedium)
                .tracking(0.5)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func spendingTrendSection(_ viewModel: AnalyticsViewModel) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text("6-Month Trend")
                    .font(AppTypography.headlineMd)
                    .foregroundStyle(.primary)
                Text("Inflows vs outflows over time")
                    .font(AppTypography.labelMedium)
                    .foregroundStyle(.tertiary)
            }

            FDSGlassSurface(cornerRadius: AppRadius.lg, padding: AppSpacing.md) {
                Chart(viewModel.monthlySummaries, id: \.id) { item in
                    BarMark(
                        x: .value("Month", item.id, unit: .month),
                        y: .value("Outflows", Double(item.totalDebit) / 100.0)
                    )
                    .foregroundStyle(AppColors.danger.opacity(0.85))
                    .cornerRadius(4)
                    .position(by: .value("Type", "Outflows"))

                    BarMark(
                        x: .value("Month", item.id, unit: .month),
                        y: .value("Inflows", Double(item.totalCredit) / 100.0)
                    )
                    .foregroundStyle(AppColors.success.opacity(0.85))
                    .cornerRadius(4)
                    .position(by: .value("Type", "Inflows"))
                }
                .frame(height: 240)
                .chartLegend(position: .bottom)
                .chartXAxis {
                    AxisMarks(format: .dateTime.month(.abbreviated))
                }
                .chartYAxis {
                    AxisMarks { _ in
                        AxisGridLine().foregroundStyle(Color.white.opacity(0.06))
                        AxisValueLabel()
                    }
                }
            }
        }
    }

    private func topMerchantsSection(_ viewModel: AnalyticsViewModel) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text("Top Merchants")
                    .font(AppTypography.headlineMd)
                    .foregroundStyle(.primary)
                Text("Highest outflow activity")
                    .font(AppTypography.labelMedium)
                    .foregroundStyle(.tertiary)
            }

            FDSGlassSurface(cornerRadius: AppRadius.lg, padding: AppSpacing.md) {
                let merchants = viewModel.topMerchants.prefix(10).map { name, amount in
                    (name: name, amount: Double(amount) / 100.0)
                }
                TopMerchantsChart(merchants: Array(merchants))
                    .frame(height: 240)
            }
        }
    }

    private var categoriesPlaceholder: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("Categories")
                .font(AppTypography.headlineMd)
                .foregroundStyle(.primary)

            FDSGlassSurface(cornerRadius: AppRadius.lg, padding: AppSpacing.xl) {
                VStack(spacing: AppSpacing.md) {
                    Image(systemName: "tag.circle.fill")
                        .font(AppTypography.displayLargeLight)
                        .foregroundStyle(AppColors.accentSlate.opacity(0.4))
                        .symbolRenderingMode(.hierarchical)
                    VStack(spacing: AppSpacing.tight) {
                        Text("Coming Soon")
                            .bodyMedium()
                        Text("Auto-categorization with smart detection")
                            .font(AppTypography.captionSm)
                            .foregroundStyle(.tertiary)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
}

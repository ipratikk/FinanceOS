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
                    .font(.system(size: 11))
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
        VStack(alignment: .leading, spacing: AppSpacing.tight) {
            Text("ANALYTICS")
                .captionSmall()
                .tracking(0.6)
                .foregroundStyle(.tertiary)
            Text("Spending Insights")
                .displayMedium()
        }
    }

    private func spendingTrendSection(_ viewModel: AnalyticsViewModel) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            FDSSectionHeader("6-Month Trend", subtitle: "Credits vs debits")

            FDSGlassSurface(cornerRadius: AppRadius.lg, padding: AppSpacing.md) {
                Chart(viewModel.monthlySummaries, id: \.id) { item in
                    BarMark(
                        x: .value("Month", item.id, unit: .month),
                        y: .value("Debits", Double(item.totalDebit) / 100.0)
                    )
                    .foregroundStyle(AppColors.debit.opacity(0.85))
                    .cornerRadius(4)
                    .position(by: .value("Type", "Debits"))

                    BarMark(
                        x: .value("Month", item.id, unit: .month),
                        y: .value("Credits", Double(item.totalCredit) / 100.0)
                    )
                    .foregroundStyle(AppColors.credit.opacity(0.85))
                    .cornerRadius(4)
                    .position(by: .value("Type", "Credits"))
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
            FDSSectionHeader("Top Merchants", subtitle: "Highest debit activity")

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
            FDSSectionHeader("Categories")

            FDSGlassSurface(cornerRadius: AppRadius.lg, padding: AppSpacing.xl) {
                VStack(spacing: AppSpacing.md) {
                    Image(systemName: "tag.circle.fill")
                        .font(.system(size: 32, weight: .regular))
                        .foregroundStyle(AppColors.accent.opacity(0.5))
                        .symbolRenderingMode(.hierarchical)
                    VStack(spacing: AppSpacing.tight) {
                        Text("Coming Soon")
                            .bodyMedium()
                        Text("Auto-categorization with smart detection")
                            .font(.system(size: 11))
                            .foregroundStyle(.tertiary)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
}

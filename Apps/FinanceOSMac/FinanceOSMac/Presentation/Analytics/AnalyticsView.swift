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
                    .foregroundColor(DesignTokens.Text.secondary)
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
        VStack(alignment: .leading, spacing: 4) {
            FDSLabel("Analytics")
                .font(AppTypography.displaySmall)
                .foregroundColor(Color(red: 0.945, green: 0.953, blue: 0.965))
            FDSLabel("Spending trends and merchant insights")
                .font(AppTypography.captionLgMedium)
                .tracking(0.3)
                .foregroundColor(Color(red: 0.741, green: 0.761, blue: 0.800))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func spendingTrendSection(_ viewModel: AnalyticsViewModel) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                FDSLabel("6-Month Trend")
                    .font(AppTypography.headingSmall)
                    .foregroundColor(Color(red: 0.945, green: 0.953, blue: 0.965))
                FDSLabel("Inflows vs outflows over time")
                    .font(AppTypography.captionLgMedium)
                    .foregroundColor(DesignTokens.Text.secondary)
            }

            FDSCard(cornerRadius: 12, padded: false) {
                Chart(viewModel.monthlySummaries, id: \.id) { item in
                    BarMark(
                        x: .value("Month", item.id, unit: .month),
                        y: .value("Outflows", Double(item.totalDebit) / 100.0)
                    )
                    .foregroundStyle(Color(red: 1.0, green: 0.27, blue: 0.23).opacity(0.8))
                    .cornerRadius(AppRadius.xs)
                    .position(by: .value("Type", "Outflows"))

                    BarMark(
                        x: .value("Month", item.id, unit: .month),
                        y: .value("Inflows", Double(item.totalCredit) / 100.0)
                    )
                    .foregroundStyle(Color(red: 0.19, green: 0.82, blue: 0.35).opacity(0.8))
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
                    .foregroundColor(Color(red: 0.945, green: 0.953, blue: 0.965))
                FDSLabel("Highest outflow activity")
                    .font(AppTypography.captionLgMedium)
                    .foregroundColor(DesignTokens.Text.secondary)
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
                .foregroundColor(Color(red: 0.945, green: 0.953, blue: 0.965))

            FDSCard(cornerRadius: 12, padded: false) {
                VStack(spacing: 12) {
                    Image(systemName: "tag.circle.fill")
                        .font(AppTypography.headingXLLight)
                        .foregroundColor(Color(red: 0.518, green: 0.541, blue: 0.580).opacity(0.4))
                        .symbolRenderingMode(.hierarchical)
                    VStack(spacing: 4) {
                        FDSLabel("Coming Soon")
                            .font(AppTypography.bodyMdSemibold)
                            .foregroundColor(Color(red: 0.945, green: 0.953, blue: 0.965))
                        FDSLabel("Auto-categorization with smart detection")
                            .font(AppTypography.captionLg)
                            .foregroundColor(DesignTokens.Text.secondary)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(AppSpacing.xl)
            }
        }
    }
}

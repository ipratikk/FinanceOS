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
            .background(Color(red: 0.039, green: 0.047, blue: 0.067))
            .task {
                await viewModel.load()
                isLoading = false
            }
        } else {
            VStack(spacing: 12) {
                ProgressView().controlSize(.small)
                Text("Loading…")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(Color(red: 0.741, green: 0.761, blue: 0.800))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(red: 0.039, green: 0.047, blue: 0.067))
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
            Text("Analytics")
                .font(.system(size: 22, weight: .semibold))
                .foregroundColor(Color(red: 0.945, green: 0.953, blue: 0.965))
            Text("Spending trends and merchant insights")
                .font(.system(size: 12, weight: .medium))
                .tracking(0.3)
                .foregroundColor(Color(red: 0.741, green: 0.761, blue: 0.800))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func spendingTrendSection(_ viewModel: AnalyticsViewModel) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("6-Month Trend")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color(red: 0.945, green: 0.953, blue: 0.965))
                Text("Inflows vs outflows over time")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color(red: 0.741, green: 0.761, blue: 0.800))
            }

            FDSCard(cornerRadius: 12, padded: false) {
                Chart(viewModel.monthlySummaries, id: \.id) { item in
                    BarMark(
                        x: .value("Month", item.id, unit: .month),
                        y: .value("Outflows", Double(item.totalDebit) / 100.0)
                    )
                    .foregroundStyle(Color(red: 1.0, green: 0.27, blue: 0.23).opacity(0.8))
                    .cornerRadius(4)
                    .position(by: .value("Type", "Outflows"))

                    BarMark(
                        x: .value("Month", item.id, unit: .month),
                        y: .value("Inflows", Double(item.totalCredit) / 100.0)
                    )
                    .foregroundStyle(Color(red: 0.19, green: 0.82, blue: 0.35).opacity(0.8))
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
                .padding(12)
            }
        }
    }

    private func topMerchantsSection(_ viewModel: AnalyticsViewModel) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Top Merchants")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color(red: 0.945, green: 0.953, blue: 0.965))
                Text("Highest outflow activity")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color(red: 0.741, green: 0.761, blue: 0.800))
            }

            FDSCard(cornerRadius: 12, padded: false) {
                let merchants = viewModel.topMerchants.prefix(10).map { name, amount in
                    (name: name, amount: Double(amount) / 100.0)
                }
                TopMerchantsChart(merchants: Array(merchants))
                    .frame(height: 240)
                    .padding(12)
            }
        }
    }

    private var categoriesPlaceholder: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Categories")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Color(red: 0.945, green: 0.953, blue: 0.965))

            FDSCard(cornerRadius: 12, padded: false) {
                VStack(spacing: 12) {
                    Image(systemName: "tag.circle.fill")
                        .font(.system(size: 40, weight: .light))
                        .foregroundColor(Color(red: 0.518, green: 0.541, blue: 0.580).opacity(0.4))
                        .symbolRenderingMode(.hierarchical)
                    VStack(spacing: 4) {
                        Text("Coming Soon")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color(red: 0.945, green: 0.953, blue: 0.965))
                        Text("Auto-categorization with smart detection")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(Color(red: 0.741, green: 0.761, blue: 0.800))
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(24)
            }
        }
    }
}

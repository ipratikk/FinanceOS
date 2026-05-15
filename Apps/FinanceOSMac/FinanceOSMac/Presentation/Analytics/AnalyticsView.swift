import Charts
import FinanceCore
import SwiftUI

struct AnalyticsView: View {
    @State private var viewModel: AnalyticsViewModel?
    @State private var isLoading = true

    private let appContainer = AppContainer.shared

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
                .padding(16)
            }
            .background(Color(red: 0.051, green: 0.051, blue: 0.059))
            .task {
                await viewModel.load()
                isLoading = false
            }
        } else {
            VStack {
                ProgressView("Loading Analytics...")
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(red: 0.051, green: 0.051, blue: 0.059))
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
            Text("Analytics")
                .font(.system(size: 22, weight: .semibold))

            Text("Spending insights & trends")
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(Color(red: 0.447, green: 0.447, blue: 0.478))
        }
    }

    var spendingTrendSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("6-Month Spending Trend")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.gray)

            if let viewModel, !viewModel.monthlySummaries.isEmpty {
                Chart(viewModel.monthlySummaries, id: \.id) { item in
                    BarMark(
                        x: .value("Month", item.id, unit: .month),
                        y: .value("Debits", Double(item.totalDebit) / 100.0)
                    )
                    .foregroundStyle(Color.red.opacity(0.8))
                    .position(by: .value("Type", "Debits"))

                    BarMark(
                        x: .value("Month", item.id, unit: .month),
                        y: .value("Credits", Double(item.totalCredit) / 100.0)
                    )
                    .foregroundStyle(Color.green.opacity(0.8))
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
                            .foregroundStyle(Color(red: 0.110, green: 0.110, blue: 0.122))
                    }
                }
                .padding(12)
                .background(Color(red: 0.110, green: 0.110, blue: 0.122))
                .cornerRadius(8)
            }
        }
        .padding(12)
        .background(Color(red: 0.086, green: 0.086, blue: 0.098))
        .cornerRadius(10)
    }

    var topMerchantsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Top Merchants")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.gray)

            if let viewModel {
                let merchants = viewModel.topMerchants.prefix(10).map { merchant, amount in
                    (name: merchant, amount: Double(amount) / 100.0)
                }
                TopMerchantsChart(merchants: Array(merchants))
            }
        }
        .padding(12)
        .background(Color(red: 0.086, green: 0.086, blue: 0.098))
        .cornerRadius(10)
    }

    var categoriesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Categories")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.gray)

            VStack(alignment: .center, spacing: 8) {
                Image(systemName: "tag.circle.fill")
                    .font(.system(size: 40, weight: .thin))
                    .foregroundColor(Color(red: 0.231, green: 0.510, blue: 0.980).opacity(0.3))

                VStack(spacing: 4) {
                    Text("Coming Soon")
                        .font(.system(size: 14, weight: .semibold))

                    Text("Auto-categorization with smart detection")
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(Color(red: 0.447, green: 0.447, blue: 0.478))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(24)
            .background(Color(red: 0.110, green: 0.110, blue: 0.122))
            .cornerRadius(8)
        }
        .padding(12)
        .background(Color(red: 0.086, green: 0.086, blue: 0.098))
        .cornerRadius(10)
    }
}

#Preview {
    AnalyticsView()
}

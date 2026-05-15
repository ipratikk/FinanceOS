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
                VStack(alignment: .leading, spacing: 20) {
                    header

                    if !viewModel.monthlySummaries.isEmpty {
                        spendingTrendSection
                    }

                    if !viewModel.topMerchants.isEmpty {
                        topMerchantsSection
                    }

                    comingSoonSection
                }
                .padding(16)
            }
            .navigationTitle("Analytics")
            .task {
                await viewModel.load()
                isLoading = false
            }
        } else {
            VStack {
                ProgressView("Loading Analytics...")
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .task {
                let vm = AnalyticsViewModel(
                    spendingService: appContainer.spendingService,
                    transactionRepository: appContainer.transactionRepository
                )
                viewModel = vm
            }
        }
    }

    var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Analytics")
                .font(.system(size: 28, weight: .bold))
            Text("Spending insights & trends")
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(.gray)
        }
    }

    var spendingTrendSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("6-Month Spending Trend")
                .font(.system(size: 16, weight: .semibold))

            if let viewModel, !viewModel.monthlySummaries.isEmpty {
                Chart(viewModel.monthlySummaries, id: \.id) { item in
                    BarMark(
                        x: .value("Month", item.id, unit: .month),
                        y: .value("Debits", Double(item.totalDebit) / 100.0)
                    )
                    .foregroundStyle(Color.red.opacity(0.7))
                    .position(by: .value("Type", "Debits"))

                    BarMark(
                        x: .value("Month", item.id, unit: .month),
                        y: .value("Credits", Double(item.totalCredit) / 100.0)
                    )
                    .foregroundStyle(Color.green.opacity(0.7))
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
                    }
                }
                .padding(16)
                .background(Color(red: 0.086, green: 0.086, blue: 0.098))
                .cornerRadius(10)
            }
        }
    }

    var topMerchantsSection: some View {
        if let viewModel {
            let merchants = viewModel.topMerchants.prefix(10).map { merchant, amount in
                (name: merchant, amount: Double(amount) / 100.0)
            }
            return AnyView(TopMerchantsChart(merchants: Array(merchants)))
        } else {
            return AnyView(EmptyView())
        }
    }

    var comingSoonSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Categories")
                .font(.system(size: 16, weight: .semibold))

            VStack(alignment: .center, spacing: 8) {
                Image(systemName: "tag")
                    .font(.system(size: 32, weight: .light))
                    .foregroundColor(.gray)

                Text("Coming Soon")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.gray)
            }
            .frame(maxWidth: .infinity)
            .padding(24)
            .background(Color(red: 0.086, green: 0.086, blue: 0.098).opacity(0.5))
            .cornerRadius(10)
        }
    }

    private func formatAmount(_ minorUnits: Int64) -> String {
        let amount = Double(minorUnits) / 100.0
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "INR"
        formatter.currencySymbol = "₹"
        return formatter.string(from: NSNumber(value: amount)) ?? "₹0.00"
    }
}

#Preview {
    AnalyticsView()
}

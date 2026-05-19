import FinanceCore
import FinanceUI
import SwiftUI

struct DashboardView: View {
    @State private var viewModel: DashboardViewModel?
    @State private var isLoading = true
    @Environment(AppNavigator.self) private var navigator

    private let appContainer = AppContainer.shared

    init() {}

    init(viewModel: DashboardViewModel) {
        _viewModel = State(initialValue: viewModel)
        _isLoading = State(initialValue: false)
    }

    var body: some View {
        if let viewModel {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    header

                    if let totals = viewModel.currentTotals {
                        heroNet(totals)
                        metricsRow(totals)
                    }

                    if !viewModel.monthlySummaries.isEmpty {
                        chartSection(viewModel)
                    }

                    if !viewModel.recentTransactions.isEmpty {
                        recentActivitySection(viewModel)
                    }
                }
                .padding(.horizontal, 40)
                .padding(.vertical, 24)
                .frame(maxWidth: 1080)
            }
            .background(Color(red: 0.039, green: 0.047, blue: 0.067))
            .task {
                await viewModel.load()
                isLoading = false
            }
        } else {
            VStack(spacing: 12) {
                ProgressView()
                    .controlSize(.small)
                Text("Loading…")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(Color(red: 0.741, green: 0.761, blue: 0.800))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(red: 0.039, green: 0.047, blue: 0.067))
            .task {
                viewModel = DashboardViewModel(
                    spendingService: appContainer.spendingService,
                    transactionRepository: appContainer.transactionRepository
                )
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Overview")
                .font(.system(size: 30, weight: .semibold))
                .foregroundColor(Color(red: 0.945, green: 0.953, blue: 0.965))
            Text(currentMonth)
                .font(.system(size: 12, weight: .medium))
                .tracking(0.3)
                .foregroundColor(Color(red: 0.741, green: 0.761, blue: 0.800))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func heroNet(_ totals: SpendingTotals) -> some View {
        let net = totals.totalCredit - totals.totalDebit
        return FDSCard(cornerRadius: 18, padded: false) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Net Flow This Month")
                    .font(.system(size: 12, weight: .medium))
                    .tracking(0.3)
                    .foregroundColor(Color(red: 0.741, green: 0.761, blue: 0.800))

                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    Text(formatAmount(net))
                        .font(.system(size: 48, weight: .semibold, design: .default))
                        .monospacedDigit()
                        .foregroundColor(net >= 0 ? Color(red: 0.19, green: 0.82, blue: 0.35) : Color(
                            red: 1.0,
                            green: 0.27,
                            blue: 0.23
                        ))
                        .contentTransition(.numericText())

                    VStack(alignment: .leading, spacing: 2) {
                        Image(systemName: net >= 0 ? "arrow.up.right" : "arrow.down.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(net >= 0 ? Color(red: 0.19, green: 0.82, blue: 0.35) : Color(
                                red: 1.0,
                                green: 0.27,
                                blue: 0.23
                            ))

                        Text(net >= 0 ? "Positive" : "Negative")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(net >= 0 ? Color(red: 0.19, green: 0.82, blue: 0.35) : Color(
                                red: 1.0,
                                green: 0.27,
                                blue: 0.23
                            ))
                    }
                }
            }
            .padding(20)
        }
    }

    private func metricsRow(_ totals: SpendingTotals) -> some View {
        HStack(spacing: 12) {
            metricCard(
                "Income",
                value: formatAmount(totals.totalCredit),
                symbol: "arrow.down.left.circle.fill",
                color: Color(red: 0.19, green: 0.82, blue: 0.35)
            )

            metricCard(
                "Spending",
                value: formatAmount(totals.totalDebit),
                symbol: "arrow.up.right.circle.fill",
                color: Color(red: 1.0, green: 0.27, blue: 0.23)
            )

            metricCard(
                "Transactions",
                value: "\(totals.transactionCount)",
                symbol: "list.bullet",
                color: Color(red: 0.518, green: 0.541, blue: 0.580)
            )
        }
    }

    private func metricCard(_ label: String, value: String, symbol: String, color: Color) -> some View {
        FDSCard(cornerRadius: 12, padded: false) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: symbol)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(color.opacity(0.6))

                    Text(label.uppercased())
                        .font(.system(size: 10, weight: .semibold))
                        .tracking(0.2)
                        .foregroundColor(Color(red: 0.741, green: 0.761, blue: 0.800))
                }

                Text(value)
                    .font(.system(size: 16, weight: .semibold, design: .default))
                    .monospacedDigit()
                    .foregroundColor(color)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
        }
    }

    private func chartSection(_ viewModel: DashboardViewModel) -> some View {
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
                SpendingTrendChart(monthlySummaries: viewModel.monthlySummaries)
                    .frame(height: 240)
                    .padding(12)
            }
        }
    }

    private func recentActivitySection(_ viewModel: DashboardViewModel) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Recent Activity")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color(red: 0.945, green: 0.953, blue: 0.965))
                    Text("Last 6 transactions")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color(red: 0.741, green: 0.761, blue: 0.800))
                }
                Spacer()
                Button(action: { navigator.navigate(to: .transactions) }) {
                    Text("View All →")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color(red: 1.0, green: 0.62, blue: 0.04))
                }
                .help("View all transactions")
            }

            FDSCard(cornerRadius: 12, padded: false) {
                VStack(spacing: 0) {
                    ForEach(
                        Array(viewModel.recentTransactions.prefix(6).enumerated()),
                        id: \.element.id
                    ) { index, txn in
                        VStack(spacing: 0) {
                            FDSTransactionRow(
                                merchant: txn.description,
                                categorySymbol: categorySymbol(for: txn.description),
                                subtitle: dateString(txn.postedAt),
                                amount: formatAmount(txn.amountMinorUnits),
                                isDebit: txn.transactionType == .debit
                            )
                            .padding(12)

                            if index < min(viewModel.recentTransactions.count, 6) - 1 {
                                Divider()
                                    .opacity(0.2)
                            }
                        }
                    }
                }
            }
        }
    }

    private var currentMonth: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: Date()).uppercased()
    }

    private func formatAmount(_ minorUnits: Int64) -> String {
        let amount = Double(minorUnits) / 100.0
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "INR"
        formatter.currencySymbol = "₹"
        return formatter.string(from: NSNumber(value: amount)) ?? "₹0.00"
    }

    private func dateString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d · h:mm a"
        return formatter.string(from: date)
    }

    private func categorySymbol(for description: String) -> String {
        let lower = description.lowercased()
        if lower.contains("salary") || lower.contains("deposit") {
            return "arrow.down.left.circle.fill"
        }
        if lower.contains("food") || lower.contains("foods") || lower.contains("market") {
            return "fork.knife"
        }
        if lower.contains("gas") || lower.contains("shell") {
            return "fuelpump.fill"
        }
        if lower.contains("coffee") || lower.contains("starbucks") {
            return "cup.and.saucer.fill"
        }
        if lower.contains("amazon") || lower.contains("target") || lower.contains("shop") {
            return "bag.fill"
        }
        return "creditcard.fill"
    }
}

#Preview {
    DashboardView()
        .environment(AppNavigator())
}

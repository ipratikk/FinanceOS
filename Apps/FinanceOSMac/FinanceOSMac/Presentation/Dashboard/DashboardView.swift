import FinanceCore
import FinanceUI
import SwiftUI

struct DashboardView: View {
    @State private var viewModel: DashboardViewModel?
    @State private var isLoading = true
    @Environment(AppNavigator.self) private var navigator

    private let appContainer = AppContainer.shared

    var body: some View {
        if let viewModel {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    header
                        .padding(.bottom, AppSpacing.lg)

                    // Net balance — hero metric
                    if let totals = viewModel.currentTotals {
                        netBalanceSection(totals)
                            .padding(.bottom, AppSpacing.lg)
                    }

                    // Summary metrics row
                    if let totals = viewModel.currentTotals {
                        metricsRow(totals)
                            .padding(.bottom, AppSpacing.lg)
                    }

                    // Chart
                    if !viewModel.monthlySummaries.isEmpty {
                        chartSection(viewModel)
                            .padding(.bottom, AppSpacing.lg)
                    }

                    // Recent transactions
                    if !viewModel.recentTransactions.isEmpty {
                        recentTransactionsSection(viewModel)
                    }
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
                ProgressView("Loading Dashboard...")
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(AppColors.base)
            .task {
                let dashboardViewModel = DashboardViewModel(
                    spendingService: appContainer.spendingService,
                    transactionRepository: appContainer.transactionRepository
                )
                viewModel = dashboardViewModel
            }
        }
    }

    var header: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xxs) {
            FDSLabel("Dashboard", style: .displayMedium)
            FDSLabel("This Month", style: .caption)
        }
    }

    private func netBalanceSection(_ totals: SpendingTotals) -> some View {
        let net = Int64(totals.totalCredit) - Int64(totals.totalDebit)
        return VStack(alignment: .leading, spacing: AppSpacing.xs) {
            FDSLabel("Net", style: .labelSmall)
            FDSLabel(formatAmount(net), style: .displayLarge)
                .foregroundColor(net >= 0 ? AppColors.credit : AppColors.debit)
        }
    }

    private func metricsRow(_ totals: SpendingTotals) -> some View {
        HStack(spacing: AppSpacing.md) {
            metricTile("Debits", formatAmount(totals.totalDebit), color: AppColors.debit)
            metricTile("Credits", formatAmount(totals.totalCredit), color: AppColors.credit)
            metricTile("Txns", "\(totals.transactionCount)", color: AppColors.accent)
        }
    }

    private func metricTile(_ label: String, _ value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.xxs) {
            FDSLabel(label, style: .labelSmall)
                .foregroundColor(AppColors.textTertiary)
            Text(value)
                .monoAmount()
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppSpacing.sm)
        .background(.ultraThinMaterial)
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.md)
                .stroke(AppColors.borderSubtle, lineWidth: 0.5)
        )
        .cornerRadius(AppRadius.md)
    }

    private func chartSection(_ viewModel: DashboardViewModel) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            FDSLabel("6-Month Trend", style: .headingMedium)
            SpendingTrendChart(monthlySummaries: viewModel.monthlySummaries)
        }
        .padding(AppSpacing.md)
        .background(.ultraThinMaterial)
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.md)
                .stroke(AppColors.borderSubtle, lineWidth: 0.5)
        )
        .cornerRadius(AppRadius.md)
    }

    private func recentTransactionsSection(_ viewModel: DashboardViewModel) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                FDSLabel("Recent Activity", style: .headingMedium)
                Spacer()
                Button(action: { navigator.navigate(to: .transactions) }) {
                    HStack(spacing: AppSpacing.xxs) {
                        FDSLabel("View All", style: .labelSmall)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundColor(AppColors.accent)
                }
                .buttonStyle(.plain)
            }

            VStack(spacing: AppSpacing.xs) {
                ForEach(Array(viewModel.recentTransactions.prefix(5)), id: \.id) { txn in
                    transactionRow(txn)
                }
            }
        }
        .padding(AppSpacing.md)
        .background(.ultraThinMaterial)
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.md)
                .stroke(AppColors.borderSubtle, lineWidth: 0.5)
        )
        .cornerRadius(AppRadius.md)
    }

    private func transactionRow(_ txn: FinanceCore.Transaction) -> some View {
        HStack(spacing: AppSpacing.md) {
            Circle()
                .fill(txn.transactionType == .debit ? AppColors.debit : AppColors.credit)
                .frame(width: 6, height: 6)

            VStack(alignment: .leading, spacing: AppSpacing.xxxs) {
                Text(txn.description)
                    .bodyMedium()
                    .lineLimit(1)
                Text(dateString(txn.postedAt))
                    .caption()
                    .foregroundColor(AppColors.textTertiary)
            }

            Spacer()

            FDSAmount(
                formatAmount(txn.amountMinorUnits),
                type: txn.transactionType == .debit ? .debit : .credit
            )
        }
        .padding(AppSpacing.sm)
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
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
}

#Preview {
    let navigator = AppNavigator()
    return DashboardView()
        .environment(navigator)
}

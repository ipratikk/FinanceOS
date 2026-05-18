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
                VStack(alignment: .leading, spacing: AppSpacing.xl) {
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
                ProgressView()
                    .controlSize(.small)
                Text("Loading…")
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(AppColors.base)
            .task {
                viewModel = DashboardViewModel(
                    spendingService: appContainer.spendingService,
                    transactionRepository: appContainer.transactionRepository
                )
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: AppSpacing.tight) {
            Text(currentMonth)
                .captionSmall()
                .tracking(0.6)
                .foregroundStyle(.tertiary)
            Text("Dashboard")
                .font(.system(size: 28, weight: .bold, design: .default))
                .foregroundStyle(.primary)
        }
    }

    private func heroNet(_ totals: SpendingTotals) -> some View {
        let net = totals.totalCredit - totals.totalDebit
        return VStack(alignment: .leading, spacing: AppSpacing.tight) {
            Text("Net This Month")
                .captionSmall()
                .tracking(0.6)
                .foregroundStyle(.tertiary)

            HStack(alignment: .firstTextBaseline, spacing: AppSpacing.compact) {
                Text(formatAmount(net))
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.primary)
                    .contentTransition(.numericText())

                Image(systemName: net >= 0 ? "arrow.up.right" : "arrow.down.right")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(net >= 0 ? AppColors.credit : AppColors.debit)
            }
        }
    }

    private func metricsRow(_ totals: SpendingTotals) -> some View {
        HStack(spacing: 0) {
            FDSMetricTile(
                "Debits",
                value: formatAmount(totals.totalDebit),
                symbol: "arrow.up.right.circle.fill"
            )

            Divider()
                .frame(height: 36)
                .padding(.horizontal, AppSpacing.md)

            FDSMetricTile(
                "Credits",
                value: formatAmount(totals.totalCredit),
                symbol: "arrow.down.left.circle.fill"
            )

            Divider()
                .frame(height: 36)
                .padding(.horizontal, AppSpacing.md)

            FDSMetricTile(
                "Transactions",
                value: "\(totals.transactionCount)",
                symbol: "list.bullet.rectangle"
            )
        }
        .padding(.vertical, AppSpacing.md)
    }

    private func chartSection(_ viewModel: DashboardViewModel) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            FDSSectionHeader("6-Month Trend", subtitle: "Credits vs debits")

            FDSGlassSurface(elevation: .card, cornerRadius: AppRadius.lg, padding: AppSpacing.md) {
                SpendingTrendChart(monthlySummaries: viewModel.monthlySummaries)
                    .frame(height: 220)
            }
        }
    }

    private func recentActivitySection(_ viewModel: DashboardViewModel) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            FDSSectionHeader(
                "Recent Activity",
                actionLabel: "View All",
                action: { navigator.navigate(to: .transactions) }
            )

            VStack(spacing: 0) {
                ForEach(Array(viewModel.recentTransactions.prefix(6).enumerated()), id: \.element.id) { index, txn in
                    FDSTransactionRow(
                        merchant: txn.description,
                        categorySymbol: categorySymbol(for: txn.description),
                        subtitle: dateString(txn.postedAt),
                        amount: formatAmount(txn.amountMinorUnits),
                        isDebit: txn.transactionType == .debit
                    )
                    if index < min(viewModel.recentTransactions.count, 6) - 1 {
                        Divider()
                            .opacity(0.3)
                            .padding(.leading, 60)
                    }
                }
            }
            .background {
                RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay {
                        RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.05), lineWidth: 0.5)
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

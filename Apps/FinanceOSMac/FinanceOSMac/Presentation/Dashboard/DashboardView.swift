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
                    .font(AppTypography.captionSm)
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
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text("Financial Overview")
                .font(AppTypography.headingLg)
                .foregroundStyle(.primary)
            Text(currentMonth)
                .font(AppTypography.labelMedium)
                .tracking(0.5)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func heroNet(_ totals: SpendingTotals) -> some View {
        let net = totals.totalCredit - totals.totalDebit
        return VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("Net Flow This Month")
                .font(AppTypography.labelMedium)
                .tracking(0.5)
                .foregroundStyle(.tertiary)

            HStack(alignment: .firstTextBaseline, spacing: AppSpacing.sm) {
                Text(formatAmount(net))
                    .font(AppTypography.displayLarge)
                    .monospacedDigit()
                    .foregroundStyle(AppColors.accentGold)
                    .contentTransition(.numericText())

                VStack(alignment: .leading, spacing: 2) {
                    Image(systemName: net >= 0 ? "arrow.up.right" : "arrow.down.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(net >= 0 ? AppColors.success : AppColors.danger)

                    Text(net >= 0 ? "Positive" : "Negative")
                        .font(AppTypography.captionSm)
                        .foregroundStyle(net >= 0 ? AppColors.success : AppColors.danger)
                }
            }
        }
        .padding(AppSpacing.lg)
        .background(.ultraThinMaterial)
        .background(AppColors.surface.opacity(0.3))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.md)
                .stroke(AppColors.accentGold.opacity(0.1), lineWidth: 0.5)
        )
        .cornerRadius(AppRadius.md)
    }

    private func metricsRow(_ totals: SpendingTotals) -> some View {
        HStack(spacing: AppSpacing.md) {
            metricCard(
                "Inflows",
                value: formatAmount(totals.totalCredit),
                symbol: "arrow.down.left.circle",
                color: AppColors.success
            )

            metricCard(
                "Outflows",
                value: formatAmount(totals.totalDebit),
                symbol: "arrow.up.right.circle",
                color: AppColors.danger
            )

            metricCard(
                "Transactions",
                value: "\(totals.transactionCount)",
                symbol: "list.bullet",
                color: AppColors.accentSlate
            )
        }
    }

    private func metricCard(_ label: String, value: String, symbol: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack(spacing: AppSpacing.xs) {
                Image(systemName: symbol)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(color.opacity(0.6))

                Text(label.uppercased())
                    .font(AppTypography.labelMedium)
                    .tracking(0.4)
                    .foregroundStyle(.tertiary)
            }

            Text(value)
                .font(AppTypography.headlineMd)
                .monospacedDigit()
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppSpacing.md)
        .background(.ultraThinMaterial)
        .background(AppColors.surface.opacity(0.2))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.md)
                .stroke(color.opacity(0.08), lineWidth: 0.5)
        )
        .cornerRadius(AppRadius.md)
    }

    private func chartSection(_ viewModel: DashboardViewModel) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text("6-Month Trend")
                    .font(AppTypography.headlineMd)
                    .foregroundStyle(.primary)
                Text("Inflows vs outflows over time")
                    .font(AppTypography.labelMedium)
                    .foregroundStyle(.tertiary)
            }

            FDSGlassSurface(elevation: .card, cornerRadius: AppRadius.lg, padding: AppSpacing.md) {
                SpendingTrendChart(monthlySummaries: viewModel.monthlySummaries)
                    .frame(height: 240)
            }
        }
    }

    private func recentActivitySection(_ viewModel: DashboardViewModel) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text("Recent Activity")
                        .font(AppTypography.headlineMd)
                        .foregroundStyle(.primary)
                    Text("Last 6 transactions")
                        .font(AppTypography.labelMedium)
                        .foregroundStyle(.tertiary)
                }
                Spacer()
                Button(action: { navigator.navigate(to: .transactions) }) {
                    Text("View All")
                        .font(AppTypography.labelMedium)
                        .foregroundStyle(AppColors.accentGold)
                }
                .help("View all transactions")
            }

            VStack(spacing: AppSpacing.xs) {
                ForEach(Array(viewModel.recentTransactions.prefix(6).enumerated()), id: \.element.id) { index, txn in
                    VStack(spacing: 0) {
                        FDSTransactionRow(
                            merchant: txn.description,
                            categorySymbol: categorySymbol(for: txn.description),
                            subtitle: dateString(txn.postedAt),
                            amount: formatAmount(txn.amountMinorUnits),
                            isDebit: txn.transactionType == .debit
                        )
                        .padding(AppSpacing.md)

                        if index < min(viewModel.recentTransactions.count, 6) - 1 {
                            Divider()
                                .opacity(0.1)
                        }
                    }
                    .background(.ultraThinMaterial)
                    .background(AppColors.surface.opacity(0.2))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppRadius.sm)
                            .stroke(AppColors.accentSlate.opacity(0.05), lineWidth: 0.5)
                    )
                    .cornerRadius(AppRadius.sm)
                }
            }
            .padding(AppSpacing.xs)
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

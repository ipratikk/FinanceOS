import FinanceCore
import FinanceUI
import SwiftUI

struct DashboardView: View {
    @State private var viewModel: DashboardViewModel?
    @State private var isLoading = true
    @Environment(AppNavigator.self) private var navigator

    init() {}

    init(viewModel: DashboardViewModel) {
        _viewModel = State(initialValue: viewModel)
        _isLoading = State(initialValue: false)
    }

    var body: some View {
        if let viewModel {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 36) {
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
                .padding(40)
                .frame(maxWidth: 1120)
                .frame(maxWidth: .infinity)
            }
            .background(AppColors.base)
            .task {
                await viewModel.load()
                isLoading = false
            }
        } else {
            VStack(spacing: AppSpacing.md) {
                ProgressView()
                    .controlSize(.regular)
                FDSLabel("Loading…")
                    .font(AppTypography.bodyMd)
                    .foregroundColor(AppColors.Text.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(AppColors.base)
            .task {
                let container = AppContainer.shared
                viewModel = DashboardViewModel(
                    spendingService: container.spendingService,
                    transactionRepository: container.transactionRepository
                )
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            FDSLabel("Overview")
                .font(AppTypography.screenTitle)
                .foregroundColor(AppColors.Text.primary)
            FDSLabel(currentMonth)
                .font(AppTypography.labelMedium)
                .tracking(0.3)
                .foregroundColor(AppColors.Text.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Hero Net Flow

    private func heroNet(_ totals: SpendingTotals) -> some View {
        let net = totals.totalCredit - totals.totalDebit
        let isPositive = net >= 0
        return FDSCard(padded: false) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 10) {
                    FDSLabel("Net Flow This Month")
                        .font(AppTypography.labelMedium)
                        .tracking(0.2)
                        .foregroundColor(AppColors.Text.secondary)

                    FDSLabel(formatAmount(net))
                        .netHeroAmount()
                        .monospacedDigit()
                        .foregroundColor(isPositive ? AppColors.success : AppColors.danger)
                        .contentTransition(.numericText())
                }

                Spacer()

                HStack(spacing: AppSpacing.compact) {
                    Image(systemName: isPositive ? "arrow.up.right" : "arrow.down.right")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(isPositive ? AppColors.success : AppColors.danger)

                    FDSLabel(isPositive ? "Positive" : "Negative")
                        .font(AppTypography.bodyMdSemibold)
                        .foregroundColor(isPositive ? AppColors.success : AppColors.danger)
                }
                .padding(.horizontal, AppSpacing.md)
                .padding(.vertical, AppSpacing.compact)
                .background(
                    Capsule()
                        .fill((isPositive ? AppColors.success : AppColors.danger).opacity(0.12))
                )
            }
            .padding(.horizontal, 36)
            .padding(.vertical, 32)
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Metrics Row

    private func metricsRow(_ totals: SpendingTotals) -> some View {
        HStack(spacing: AppSpacing.md) {
            metricTile(
                "Income",
                value: formatAmount(totals.totalCredit),
                symbol: "arrow.down.left.circle.fill",
                color: AppColors.success
            )
            metricTile(
                "Spending",
                value: formatAmount(totals.totalDebit),
                symbol: "arrow.up.right.circle.fill",
                color: AppColors.danger
            )
            metricTile(
                "Transactions",
                value: "\(totals.transactionCount)",
                symbol: "list.bullet",
                color: AppColors.Text.secondary
            )
        }
    }

    private func metricTile(_ label: String, value: String, symbol: String, color: Color) -> some View {
        FDSCard(padded: false) {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                HStack(spacing: AppSpacing.tight) {
                    Image(systemName: symbol)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(color.opacity(0.8))
                    FDSLabel(label.uppercased())
                        .font(AppTypography.captionLgSemibold)
                        .tracking(0.6)
                        .foregroundColor(AppColors.Text.secondary)
                }
                FDSLabel(value)
                    .font(AppTypography.headingLg)
                    .monospacedDigit()
                    .foregroundColor(color)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
        }
    }

    // MARK: - Chart

    private func chartSection(_ viewModel: DashboardViewModel) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            sectionHeader("6-Month Trend", subtitle: "Inflows vs outflows over time")

            FDSCard(padded: false) {
                SpendingTrendChart(monthlySummaries: viewModel.monthlySummaries)
                    .frame(height: 280)
                    .padding(AppSpacing.xl)
            }
        }
    }

    // MARK: - Recent Activity

    private func recentActivitySection(_ viewModel: DashboardViewModel) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                sectionHeader(
                    "Recent Activity",
                    subtitle: "Last \(min(viewModel.recentTransactions.count, 6)) transactions"
                )
                Spacer()
                Button { navigator.navigate(to: .transactions) } label: {
                    HStack(spacing: 4) {
                        FDSLabel("View All")
                            .font(AppTypography.captionLgMedium)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundStyle(AppColors.accent)
                }
                .buttonStyle(.plain)
            }

            FDSCard(cornerRadius: AppRadius.lg, padded: false) {
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
                                amount: formatAmount(txn.amountMinorUnits, currencyCode: txn.currencyCode),
                                isDebit: txn.transactionType == .debit
                            )

                            if index < min(viewModel.recentTransactions.count, 6) - 1 {
                                Divider()
                                    .padding(.leading, 68)
                                    .opacity(0.12)
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Shared section header

    private func sectionHeader(_ title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            FDSLabel(title)
                .font(AppTypography.headingSmall)
                .foregroundStyle(AppColors.Text.primary)
            FDSLabel(subtitle)
                .font(AppTypography.captionLg)
                .foregroundStyle(AppColors.Text.tertiary)
        }
    }

    // MARK: - Helpers

    private var currentMonth: String {
        FormatterCache.formatMonthYear(Date()).uppercased()
    }

    private func formatAmount(_ minorUnits: Int64) -> String {
        FormatterCache.formatCurrency(Decimal(minorUnits) / 100, currencyCode: "INR")
    }

    private func formatAmount(_ minorUnits: Int64, currencyCode: String) -> String {
        FormatterCache.formatCurrency(Decimal(minorUnits) / 100, currencyCode: currencyCode)
    }

    private func dateString(_ date: Date) -> String {
        FormatterCache.formatDateTime(date)
    }

    private func categorySymbol(for description: String) -> String {
        let lower = description.lowercased()
        if lower.contains("salary") || lower.contains("deposit") { return "arrow.down.left.circle.fill" }
        if lower.contains("food") || lower.contains("foods") || lower.contains("market") { return "fork.knife" }
        if lower.contains("gas") || lower.contains("shell") { return "fuelpump.fill" }
        if lower.contains("coffee") || lower.contains("starbucks") { return "cup.and.saucer.fill" }
        if lower.contains("amazon") || lower.contains("target") || lower.contains("shop") { return "bag.fill" }
        return "creditcard.fill"
    }
}

#Preview {
    DashboardView()
        .environment(AppNavigator())
}

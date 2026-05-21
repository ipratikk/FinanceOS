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
            .background(AppColors.base)
            .task {
                await viewModel.load()
                isLoading = false
            }
        } else {
            VStack(spacing: 12) {
                ProgressView()
                    .controlSize(.small)
                FDSLabel("Loading…")
                    .font(AppTypography.captionSmMedium)
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

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            FDSLabel("Overview")
                .font(AppTypography.screenTitle)
                .foregroundColor(AppColors.Text.primary)
            FDSLabel(currentMonth)
                .font(AppTypography.captionLgMedium)
                .tracking(0.2)
                .foregroundColor(AppColors.Text.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func heroNet(_ totals: SpendingTotals) -> some View {
        let net = totals.totalCredit - totals.totalDebit
        return FDSCard(cornerRadius: 18, padded: false) {
            VStack(alignment: .leading, spacing: 12) {
                FDSLabel("Net Flow This Month")
                    .font(AppTypography.captionLgMedium)
                    .tracking(0.2)
                    .foregroundColor(AppColors.Text.secondary)

                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    FDSLabel(formatAmount(net))
                        .netHeroAmount()
                        .monospacedDigit()
                        .foregroundColor(net >= 0 ? AppColors.success : AppColors.danger)
                        .contentTransition(.numericText())

                    VStack(alignment: .leading, spacing: 2) {
                        Image(systemName: net >= 0 ? "arrow.up.right" : "arrow.down.right")
                            .font(AppTypography.captionLgSemibold)
                            .foregroundColor(net >= 0 ? AppColors.success : AppColors.danger)

                        FDSLabel(net >= 0 ? "Positive" : "Negative")
                            .font(AppTypography.captionSmMedium)
                            .foregroundColor(net >= 0 ? AppColors.success : AppColors.danger)
                    }
                }
            }
            .padding(AppSpacing.md)
        }
    }

    private func metricsRow(_ totals: SpendingTotals) -> some View {
        HStack(spacing: 12) {
            metricCard(
                "Income",
                value: formatAmount(totals.totalCredit),
                symbol: "arrow.down.left.circle.fill",
                color: AppColors.success
            )

            metricCard(
                "Spending",
                value: formatAmount(totals.totalDebit),
                symbol: "arrow.up.right.circle.fill",
                color: AppColors.danger
            )

            metricCard(
                "Transactions",
                value: "\(totals.transactionCount)",
                symbol: "list.bullet",
                color: AppColors.Text.tertiary
            )
        }
    }

    private func metricCard(_ label: String, value: String, symbol: String, color: Color) -> some View {
        FDSCard(cornerRadius: 12, padded: false) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: symbol)
                        .font(AppTypography.captionLgSemibold)
                        .foregroundColor(color.opacity(0.6))

                    FDSLabel(label.uppercased())
                        .font(AppTypography.captionSmSemibold)
                        .tracking(0.2)
                        .foregroundColor(AppColors.Text.secondary)
                }

                FDSLabel(value)
                    .font(AppTypography.headingSmall)
                    .monospacedDigit()
                    .foregroundColor(color)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(AppSpacing.xs)
        }
    }

    private func chartSection(_ viewModel: DashboardViewModel) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                FDSLabel("6-Month Trend")
                    .font(AppTypography.headingSmall)
                    .foregroundColor(AppColors.Text.primary)
                FDSLabel("Inflows vs outflows over time")
                    .font(AppTypography.captionLgMedium)
                    .foregroundColor(AppColors.Text.secondary)
            }

            FDSCard(cornerRadius: 12, padded: false) {
                SpendingTrendChart(monthlySummaries: viewModel.monthlySummaries)
                    .frame(height: 240)
                    .padding(AppSpacing.xs)
            }
        }
    }

    private func recentActivitySection(_ viewModel: DashboardViewModel) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    FDSLabel("Recent Activity")
                        .font(AppTypography.headingSmall)
                        .foregroundColor(AppColors.Text.primary)
                    FDSLabel("Last 6 transactions")
                        .font(AppTypography.captionLgMedium)
                        .foregroundColor(AppColors.Text.secondary)
                }
                Spacer()
                Button(action: { navigator.navigate(to: .transactions) }, label: {
                    FDSLabel("View All →")
                        .font(AppTypography.captionLgSemibold)
                        .foregroundColor(AppColors.accentOrange)
                })
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
                                amount: formatAmount(txn.amountMinorUnits, currencyCode: txn.currencyCode),
                                isDebit: txn.transactionType == .debit
                            )
                            .padding(AppSpacing.xs)

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
        FormatterCache.formatMonthYear(Date()).uppercased()
    }

    /// For totals (aggregated across accounts) we display in INR — the app's primary currency.
    /// Individual transaction rows use their own currencyCode via the overload below.
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

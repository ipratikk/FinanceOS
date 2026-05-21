import Charts
import FinanceCore
import FinanceUI
import SwiftUI

// MARK: - Net Worth Hero

extension DashboardView {
    func netWorthHero(_ viewModel: DashboardViewModel) -> some View {
        let totals = viewModel.currentTotals
        let net = (totals?.totalCredit ?? 0) - (totals?.totalDebit ?? 0)
        let isPositive = net >= 0

        return FDSCard(padded: false) {
            VStack(alignment: .leading, spacing: 16) {
                // Header row
                HStack {
                    FDSLabel("NET FLOW THIS MONTH")
                        .font(AppTypography.captionSmSemibold)
                        .tracking(0.8)
                        .foregroundStyle(AppColors.Text.tertiary)
                    Spacer()
                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                        .foregroundStyle(AppColors.Text.quaternary)
                    Image(systemName: "ellipsis")
                        .foregroundStyle(AppColors.Text.quaternary)
                }

                // Amount + delta badge
                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    FDSLabel(amount(net))
                        .font(.system(size: 44, weight: .bold, design: .monospaced))
                        .foregroundStyle(isPositive ? AppColors.success : AppColors.danger)
                        .lineLimit(1)

                    if !viewModel.monthlySummaries.isEmpty {
                        Text(isPositive ? "+12.4%" : "-4.2%")
                            .font(AppTypography.captionLgSemibold)
                            .foregroundStyle(AppColors.success)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(AppColors.success.opacity(0.15), in: Capsule())
                    }
                }

                // Trend line chart
                if !viewModel.monthlySummaries.isEmpty {
                    netWorthChart(viewModel.monthlySummaries)
                        .frame(height: 140)
                }

                // Legend
                HStack(spacing: 20) {
                    legendDot("Liquid Assets", "₹45.2L", AppColors.success)
                    legendDot("Investments", "₹89.3L", AppColors.accentBlue)
                }
            }
            .padding(24)
        }
    }

    private func netWorthChart(_ data: [MonthlySpendingSummary]) -> some View {
        Chart(data, id: \.id) { item in
            AreaMark(
                x: .value("Month", item.month, unit: .month),
                y: .value("Amount", Double(item.totalCredit) / 100)
            )
            .foregroundStyle(
                LinearGradient(
                    colors: [AppColors.success.opacity(0.25), AppColors.success.opacity(0)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .interpolationMethod(.catmullRom)

            LineMark(
                x: .value("Month", item.month, unit: .month),
                y: .value("Amount", Double(item.totalCredit) / 100)
            )
            .foregroundStyle(AppColors.success)
            .lineStyle(StrokeStyle(lineWidth: 2.5))
            .interpolationMethod(.catmullRom)
        }
        .chartXAxis { AxisMarks(format: .dateTime.month(.abbreviated)) }
        .chartYAxis(.hidden)
        .chartPlotStyle { $0.background(Color.clear) }
    }

    private func legendDot(_ label: String, _ value: String, _ color: Color) -> some View {
        HStack(spacing: 6) {
            Circle().fill(color).frame(width: 7, height: 7)
            FDSLabel(label)
                .font(AppTypography.captionSm)
                .foregroundStyle(AppColors.Text.tertiary)
            FDSLabel(value)
                .font(AppTypography.captionSmSemibold)
                .foregroundStyle(AppColors.Text.secondary)
        }
    }
}

// MARK: - Wealth Intelligence

extension DashboardView {
    var wealthIntelCard: some View {
        FDSCard(padded: false) {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(AppColors.accent)
                    FDSLabel("Wealth Intelligence")
                        .font(AppTypography.bodyMdSemibold)
                        .foregroundStyle(AppColors.Text.primary)
                }

                intelInsight(
                    title: "Portfolio Rebalance",
                    body: "Your exposure to Tech stocks has grown to 45%. Consider diversifying into Bonds to reduce risk."
                )
                intelInsight(
                    title: "Savings Target",
                    body: "You're 84% through your Q2 retirement goal. ₹1.2L more needed to stay on track."
                )

                Spacer()

                Button {
                    // future: navigate to AI insights
                } label: {
                    HStack {
                        FDSLabel("Run full analysis")
                            .font(AppTypography.bodySmSemibold)
                            .foregroundStyle(AppColors.accent)
                        Image(systemName: "arrow.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(AppColors.accent)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .glassSurface(radius: AppRadius.md, lifted: false)
                }
                .buttonStyle(.plain)
            }
            .padding(20)
        }
    }

    private func intelInsight(title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            FDSLabel(title)
                .font(AppTypography.bodySmSemibold)
                .foregroundStyle(AppColors.Text.primary)
            FDSLabel(body)
                .font(AppTypography.captionLg)
                .foregroundStyle(AppColors.Text.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.Fill.primary, in: RoundedRectangle(cornerRadius: AppRadius.sm))
    }
}

// MARK: - Metric Tiles

extension DashboardView {
    func metricsRow(_ totals: SpendingTotals) -> some View {
        HStack(spacing: 20) {
            metricTile(
                label: "MONTHLY INFLOWS",
                value: amount(totals.totalCredit),
                badge: "+12.4%",
                badgeColor: AppColors.success,
                amountColor: AppColors.Text.primary,
                progress: 0.62
            )
            metricTile(
                label: "MONTHLY OUTFLOWS",
                value: amount(totals.totalDebit),
                badge: "-4.2%",
                badgeColor: AppColors.danger,
                amountColor: AppColors.danger,
                progress: 0.44
            )
            let net = totals.totalCredit - totals.totalDebit
            metricTile(
                label: "NET SAVINGS",
                value: amount(max(0, net)),
                badge: "\(totals.transactionCount) Txns",
                badgeColor: AppColors.Text.tertiary,
                amountColor: AppColors.success,
                progress: 0.78
            )
        }
    }

    private func metricTile(
        label: String,
        value: String,
        badge: String,
        badgeColor: Color,
        amountColor: Color,
        progress: Double
    ) -> some View {
        FDSCard(padded: false) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    FDSLabel(label)
                        .font(AppTypography.captionSmSemibold)
                        .tracking(0.7)
                        .foregroundStyle(AppColors.Text.tertiary)
                    Spacer()
                    FDSLabel(badge)
                        .font(AppTypography.captionSmSemibold)
                        .foregroundStyle(badgeColor)
                }

                FDSLabel(value)
                    .font(AppTypography.headingMd)
                    .monospacedDigit()
                    .foregroundStyle(amountColor)
                    .lineLimit(1)

                progressBar(progress, color: amountColor == AppColors.danger ? AppColors.danger : AppColors.success)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 18)
        }
    }

    private func progressBar(_ fraction: Double, color: Color) -> some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(color.opacity(0.12))
                    .frame(height: 4)
                RoundedRectangle(cornerRadius: 2)
                    .fill(color)
                    .frame(width: geo.size.width * fraction, height: 4)
            }
        }
        .frame(height: 4)
    }
}

// MARK: - Asset Distribution

extension DashboardView {
    var assetDistCard: some View {
        FDSCard(padded: false) {
            VStack(alignment: .leading, spacing: 16) {
                FDSLabel("Asset Distribution")
                    .font(AppTypography.headingSmall)
                    .foregroundStyle(AppColors.Text.primary)

                assetRow(
                    symbol: "banknote",
                    tint: AppColors.success,
                    label: "Cash & Savings",
                    sub: "3 Accounts",
                    amount: "₹24.8L",
                    pct: "18%",
                    color: AppColors.success
                )

                assetRow(
                    symbol: "chart.line.uptrend.xyaxis",
                    tint: AppColors.accentBlue,
                    label: "Stock Portfolio",
                    sub: "2 Brokers",
                    amount: "₹64.2L",
                    pct: "48%",
                    color: AppColors.accentBlue
                )

                assetRow(
                    symbol: "building.columns",
                    tint: AppColors.accentOrange,
                    label: "Mutual Funds",
                    sub: "12 Folios",
                    amount: "₹45.6L",
                    pct: "34%",
                    color: AppColors.accentOrange
                )
            }
            .padding(20)
        }
    }

    private func assetRow(
        symbol: String, tint: Color,
        label: String, sub: String,
        amount: String, pct: String, color: Color
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: symbol)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 32, height: 32)
                .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: AppRadius.chip))

            VStack(alignment: .leading, spacing: 1) {
                FDSLabel(label)
                    .font(AppTypography.bodySmMedium)
                    .foregroundStyle(AppColors.Text.primary)
                FDSLabel(sub)
                    .font(AppTypography.captionSm)
                    .foregroundStyle(AppColors.Text.tertiary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 1) {
                FDSLabel(amount)
                    .font(AppTypography.bodySmSemibold)
                    .foregroundStyle(AppColors.Text.primary)
                    .monospacedDigit()
                FDSLabel(pct)
                    .font(AppTypography.captionSm)
                    .foregroundStyle(color)
            }
        }
    }
}

// MARK: - Recent Activity

extension DashboardView {
    func recentActivityCard(_ viewModel: DashboardViewModel) -> some View {
        FDSCard(padded: false) {
            VStack(alignment: .leading, spacing: 0) {
                // Header
                HStack {
                    FDSLabel("Recent Activity")
                        .font(AppTypography.headingSmall)
                        .foregroundStyle(AppColors.Text.primary)
                    Spacer()
                    Button { navigator.navigate(to: .transactions) } label: {
                        FDSLabel("View all")
                            .font(AppTypography.captionLgSemibold)
                            .foregroundStyle(AppColors.accent)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)

                // Column headers
                HStack {
                    FDSLabel("STATUS").frame(width: 72, alignment: .leading)
                    FDSLabel("MERCHANT").frame(maxWidth: .infinity, alignment: .leading)
                    FDSLabel("CATEGORY").frame(width: 110, alignment: .leading)
                    FDSLabel("AMOUNT").frame(width: 100, alignment: .trailing)
                }
                .font(AppTypography.captionSmSemibold)
                .tracking(0.6)
                .foregroundStyle(AppColors.Text.quaternary)
                .padding(.horizontal, 20)
                .padding(.bottom, 8)

                Divider().opacity(0.1)

                // Rows
                let txns = Array(viewModel.recentTransactions.prefix(6))
                ForEach(Array(txns.enumerated()), id: \.element.id) { idx, txn in
                    activityRow(txn, isNew: idx < 2)
                    if idx < txns.count - 1 {
                        Divider().padding(.horizontal, 20).opacity(0.08)
                    }
                }
            }
            .padding(.bottom, 8)
        }
    }

    private func activityRow(_ txn: Transaction, isNew: Bool) -> some View {
        HStack(spacing: 0) {
            statusBadge(isNew: isNew)
                .frame(width: 72, alignment: .leading)

            HStack(spacing: 10) {
                Circle()
                    .fill(AppColors.Fill.secondary)
                    .frame(width: 30, height: 30)
                    .overlay {
                        Image(systemName: categorySymbol(for: txn.description))
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(AppColors.Text.secondary)
                    }
                FDSLabel(txn.description)
                    .font(AppTypography.bodySmMedium)
                    .foregroundStyle(AppColors.Text.primary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            FDSLabel(categoryName(for: txn.description))
                .font(AppTypography.captionLg)
                .foregroundStyle(AppColors.Text.tertiary)
                .frame(width: 110, alignment: .leading)
                .lineLimit(1)

            let isDebit = txn.transactionType == .debit
            FDSLabel((isDebit ? "-" : "+") + amount(txn.amountMinorUnits, code: txn.currencyCode))
                .font(AppTypography.bodySmSemibold)
                .monospacedDigit()
                .foregroundStyle(isDebit ? AppColors.danger : AppColors.success)
                .frame(width: 100, alignment: .trailing)
                .lineLimit(1)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }

    private func statusBadge(isNew: Bool) -> some View {
        FDSLabel(isNew ? "NEW" : "CLEARED")
            .font(AppTypography.captionSmSemibold)
            .tracking(0.4)
            .foregroundStyle(isNew ? AppColors.Text.primary : AppColors.Text.tertiary)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(
                isNew ? AppColors.Fill.tertiary : AppColors.Fill.primary,
                in: RoundedRectangle(cornerRadius: AppRadius.chip)
            )
    }

    private func categorySymbol(for description: String) -> String {
        let lower = description.lowercased()
        if lower.contains("salary") || lower.contains("credit") { return "arrow.down.left.circle.fill" }
        if lower.contains("food") || lower.contains("zomato") { return "fork.knife" }
        if lower.contains("netflix") || lower.contains("spotify") { return "play.tv.fill" }
        if lower.contains("amazon") || lower.contains("flipkart") { return "bag.fill" }
        if lower.contains("apple") { return "laptopcomputer" }
        if lower.contains("uber") || lower.contains("ola") { return "car.fill" }
        return "creditcard.fill"
    }
}

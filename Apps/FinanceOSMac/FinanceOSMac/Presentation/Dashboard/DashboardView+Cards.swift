import Charts
import FinanceCore
import FinanceUI
import SwiftUI

// MARK: - Configuration Models

struct MetricConfig {
    let label: String
    let value: String
    let badge: String
    let badgeColor: Color
    let amountColor: Color
    let progress: Double
}

struct AssetRowConfig {
    let symbol: String
    let tint: Color
    let label: String
    let sub: String
    let amount: String
    let pct: String
    let color: Color
}

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
                        .font(AppTypography.displayLarge)
                        .monospacedDigit()
                        .foregroundStyle(isPositive ? AppColors.success : AppColors.danger)
                        .lineLimit(1)

                    if !viewModel.monthlySummaries.isEmpty {
                        FDSLabel(isPositive ? "+12.4%" : "-4.2%")
                            .font(AppTypography.captionLgSemibold)
                            .foregroundStyle(AppColors.success)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(AppColors.success.opacity(0.15), in: Capsule())
                    }
                }

                Spacer()

                // Trend line chart
                netWorthChart(viewModel.monthlySummaries)
                    .frame(height: 140)

                // Legend
                HStack(spacing: 20) {
                    legendDot("Liquid Assets", "₹45.2L", AppColors.success)
                    legendDot("Investments", "₹89.3L", AppColors.accentBlue)
                }
            }
            .padding(AppSpacing.xl)
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
                        .font(AppTypography.captionLgSemibold)
                        .foregroundStyle(AppColors.accent)
                    FDSLabel("Wealth Intelligence")
                        .font(AppTypography.bodyMdSemibold)
                        .foregroundStyle(AppColors.Text.primary)
                }

                intelInsight(
                    title: "Portfolio Rebalance",
                    body: "Your exposure to Tech stocks has grown to 45%. "
                        + "Consider diversifying into Bonds to reduce risk."
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
                            .font(AppTypography.captionSmSemibold)
                            .foregroundStyle(AppColors.accent)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .glassSurface(radius: AppRadius.md, lifted: false)
                }
                .buttonStyle(.plain)
            }
            .padding(AppSpacing.lg)
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
        .padding(AppSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.Fill.primary, in: RoundedRectangle(cornerRadius: AppRadius.sm))
    }
}

// MARK: - Metric Tiles

extension DashboardView {
    func metricsRow(_ totals: SpendingTotals) -> some View {
        HStack(spacing: 20) {
            metricTile(
                .init(
                    label: "MONTHLY INFLOWS",
                    value: amount(totals.totalCredit),
                    badge: "+12.4%",
                    badgeColor: AppColors.success,
                    amountColor: AppColors.Text.primary,
                    progress: 0.62
                )
            )
            metricTile(
                .init(
                    label: "MONTHLY OUTFLOWS",
                    value: amount(totals.totalDebit),
                    badge: "-4.2%",
                    badgeColor: AppColors.danger,
                    amountColor: AppColors.danger,
                    progress: 0.44
                )
            )
            let net = totals.totalCredit - totals.totalDebit
            metricTile(
                .init(
                    label: "NET SAVINGS",
                    value: amount(max(0, net)),
                    badge: "\(totals.transactionCount) Txns",
                    badgeColor: AppColors.Text.tertiary,
                    amountColor: AppColors.success,
                    progress: 0.78
                )
            )
        }
    }

    private func metricTile(_ config: MetricConfig) -> some View {
        FDSCard(padded: false) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    FDSLabel(config.label)
                        .font(AppTypography.captionSmSemibold)
                        .tracking(0.7)
                        .foregroundStyle(AppColors.Text.tertiary)
                    Spacer()
                    FDSLabel(config.badge)
                        .font(AppTypography.captionSmSemibold)
                        .foregroundStyle(config.badgeColor)
                }

                FDSLabel(config.value)
                    .font(AppTypography.headingMd)
                    .monospacedDigit()
                    .foregroundStyle(config.amountColor)
                    .lineLimit(1)

                progressBar(
                    config.progress,
                    color: config.amountColor == AppColors.danger
                        ? AppColors.danger : AppColors.success
                )
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

                assetRow(.init(
                    symbol: "banknote",
                    tint: AppColors.success,
                    label: "Cash & Savings",
                    sub: "3 Accounts",
                    amount: "₹24.8L",
                    pct: "18%",
                    color: AppColors.success
                ))

                assetRow(.init(
                    symbol: "chart.line.uptrend.xyaxis",
                    tint: AppColors.accentBlue,
                    label: "Stock Portfolio",
                    sub: "2 Brokers",
                    amount: "₹64.2L",
                    pct: "48%",
                    color: AppColors.accentBlue
                ))

                assetRow(.init(
                    symbol: "building.columns",
                    tint: AppColors.accentOrange,
                    label: "Mutual Funds",
                    sub: "12 Folios",
                    amount: "₹45.6L",
                    pct: "34%",
                    color: AppColors.accentOrange
                ))
            }
            .padding(AppSpacing.lg)
        }
    }

    private func assetRow(_ config: AssetRowConfig) -> some View {
        HStack(spacing: 12) {
            Image(systemName: config.symbol)
                .font(AppTypography.captionSmSemibold)
                .foregroundStyle(config.tint)
                .frame(width: 32, height: 32)
                .background(
                    config.tint.opacity(0.12),
                    in: RoundedRectangle(cornerRadius: AppRadius.chip)
                )

            VStack(alignment: .leading, spacing: 1) {
                FDSLabel(config.label)
                    .font(AppTypography.bodySmMedium)
                    .foregroundStyle(AppColors.Text.primary)
                FDSLabel(config.sub)
                    .font(AppTypography.captionSm)
                    .foregroundStyle(AppColors.Text.tertiary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 1) {
                FDSLabel(config.amount)
                    .font(AppTypography.bodySmSemibold)
                    .foregroundStyle(AppColors.Text.primary)
                    .monospacedDigit()
                FDSLabel(config.pct)
                    .font(AppTypography.captionSm)
                    .foregroundStyle(config.color)
            }
        }
    }
}

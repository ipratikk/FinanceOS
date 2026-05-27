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

// MARK: - Net Worth Hero

extension DashboardView {
    func netWorthHero(_ viewModel: DashboardViewModel) -> some View {
        let netWorth = viewModel.currentNetWorth
        let isPositive = netWorth >= 0

        return FDSCard(padded: false) {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    FDSLabel("NET WORTH")
                        .font(AppTypography.captionSmSemibold)
                        .tracking(0.8)
                        .foregroundStyle(AppColors.Text.tertiary)
                    Spacer()
                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                        .foregroundStyle(AppColors.Text.quaternary)
                    Image(systemName: "ellipsis")
                        .foregroundStyle(AppColors.Text.quaternary)
                }

                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    FDSLabel(FormatterCache.formatCurrency(netWorth, currencyCode: "INR"))
                        .font(AppTypography.displayLarge)
                        .monospacedDigit()
                        .foregroundStyle(isPositive ? AppColors.Text.primary : AppColors.danger)
                        .lineLimit(1)

                    if let delta = viewModel.netWorthMoMDelta {
                        let deltaStr = delta >= 0
                            ? String(format: "+%.1f%%", delta * 100)
                            : String(format: "%.1f%%", delta * 100)
                        FDSLabel(deltaStr)
                            .font(AppTypography.captionLgSemibold)
                            .foregroundStyle(delta >= 0 ? AppColors.success : AppColors.danger)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(
                                (delta >= 0 ? AppColors.success : AppColors.danger).opacity(0.15),
                                in: Capsule()
                            )
                    }
                }

                Spacer()

                CombinedFinancialChartView(netWorth: viewModel.netWorthTimeSeries)
                    .frame(height: 220)
            }
            .padding(AppSpacing.xl)
        }
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

// MARK: - Metric Tiles

extension DashboardView {
    func metricsRow(_ totals: SpendingTotals) -> some View {
        HStack(spacing: 20) {
            metricTile(
                .init(
                    label: "MONTHLY INFLOWS",
                    value: amount(totals.totalCredit),
                    badge: "",
                    badgeColor: AppColors.Text.tertiary,
                    amountColor: AppColors.Text.primary,
                    progress: 0.0
                )
            )
            metricTile(
                .init(
                    label: "MONTHLY OUTFLOWS",
                    value: amount(totals.totalDebit),
                    badge: "",
                    badgeColor: AppColors.Text.tertiary,
                    amountColor: AppColors.danger,
                    progress: 0.0
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
                    progress: 0.0
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

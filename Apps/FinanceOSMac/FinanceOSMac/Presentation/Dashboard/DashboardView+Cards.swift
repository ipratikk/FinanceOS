import AppKit
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
        FDSCard(padded: false) {
            VStack(alignment: .leading, spacing: 16) {
                heroHeader(viewModel)
                heroAmount(viewModel)
                Spacer()
                CombinedFinancialChartView(
                    netWorth: viewModel.netWorthTimeSeries,
                    visibleDays: viewModel.selectedTimeRange.visibleDays
                )
                .id(viewModel.selectedTimeRange)
                .frame(height: 220)
            }
            .padding(AppSpacing.xl)
        }
    }

    private func heroHeader(_ viewModel: DashboardViewModel) -> some View {
        HStack {
            FDSLabel("NET WORTH")
                .font(AppTypography.captionSmSemibold)
                .tracking(0.8)
                .foregroundStyle(AppColors.Text.tertiary)
            Spacer()
            heroActions(viewModel)
        }
    }

    private func heroActions(_ viewModel: DashboardViewModel) -> some View {
        HStack(spacing: 4) {
            Button {
                showNetWorthDetail = true
            } label: {
                Image(systemName: "arrow.up.left.and.arrow.down.right")
                    .foregroundStyle(AppColors.Text.quaternary)
                    .frame(width: 32, height: 32)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Menu {
                heroTimeRangeMenu(viewModel)
                Divider()
                Button("Set Opening Balance") {
                    showOpeningBalanceSheet = true
                }
                Button("Export Chart Data") {
                    let csv = viewModel.exportNetWorthCSV()
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(csv, forType: .string)
                }
            } label: {
                Image(systemName: "ellipsis")
                    .foregroundStyle(AppColors.Text.quaternary)
                    .frame(width: 32, height: 32)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }

    private func heroTimeRangeMenu(_ viewModel: DashboardViewModel) -> some View {
        Menu("Time Range") {
            ForEach(TimeRange.allCases) { range in
                Button {
                    Task { await viewModel.setTimeRange(range) }
                } label: {
                    if viewModel.selectedTimeRange == range {
                        Label(range.rawValue, systemImage: "checkmark")
                    } else {
                        FDSLabel(range.rawValue)
                    }
                }
            }
        }
    }

    private func heroAmount(_ viewModel: DashboardViewModel) -> some View {
        let netWorth = viewModel.currentNetWorth
        let isPositive = netWorth >= 0
        return HStack(alignment: .firstTextBaseline, spacing: 12) {
            FDSLabel(FormatterCache.formatCurrency(netWorth, currencyCode: "INR"))
                .font(AppTypography.displayLarge)
                .monospacedDigit()
                .foregroundStyle(isPositive ? AppColors.Text.primary : AppColors.danger)
                .lineLimit(1)
            if let delta = viewModel.netWorthMoMDelta {
                heroDeltaBadge(delta)
            }
        }
    }

    private func heroDeltaBadge(_ delta: Double) -> some View {
        let deltaStr = delta >= 0
            ? String(format: "+%.1f%%", delta * 100)
            : String(format: "%.1f%%", delta * 100)
        return VStack(alignment: .leading, spacing: 2) {
            FDSLabel(deltaStr)
                .font(AppTypography.captionLgSemibold)
                .foregroundStyle(delta >= 0 ? AppColors.success : AppColors.danger)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(
                    (delta >= 0 ? AppColors.success : AppColors.danger).opacity(0.15),
                    in: Capsule()
                )
            FDSLabel("vs last month")
                .font(AppTypography.captionSm)
                .foregroundStyle(AppColors.Text.quaternary)
                .padding(.leading, 8)
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

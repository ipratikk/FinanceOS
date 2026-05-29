import Charts
import FinanceCore
import FinanceUI
import SwiftUI

struct SpendingTrendCard: View {
    let summaries: [MonthlySpendingSummary]
    let totalOutflowText: String
    let periodLabel: String
    let outflowChange: Double?

    var body: some View {
        FDSCard(cornerRadius: 16, padded: false) {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                headerRow
                chart
            }
            .padding(AppSpacing.md)
        }
    }

    private var headerRow: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                FDSLabel("TOTAL OUTFLOW")
                    .font(AppTypography.captionSmSemibold)
                    .tracking(1.0)
                    .foregroundStyle(AppColors.Text.secondary)
                HStack(alignment: .firstTextBaseline, spacing: AppSpacing.compact) {
                    FDSLabel(totalOutflowText)
                        .font(AppTypography.headingLg)
                        .foregroundStyle(AppColors.Text.primary)
                        .monospacedDigit()
                    if let change = outflowChange {
                        changeChip(change)
                    }
                }
            }
            Spacer()
            HStack(spacing: AppSpacing.compact) {
                chip("SPENDING TRENDS", color: AppColors.accentGreen.opacity(0.15), textColor: AppColors.accentGreen)
                chip(periodLabel, color: AppColors.Text.secondary.opacity(0.1), textColor: AppColors.Text.secondary)
            }
        }
    }

    private var chart: some View {
        Chart(summaries, id: \.id) { item in
            AreaMark(
                x: .value("Month", item.id, unit: .month),
                y: .value("Outflow", Double(item.totalDebit) / 100.0)
            )
            .foregroundStyle(
                LinearGradient(
                    colors: [AppColors.accentGreen.opacity(0.3), AppColors.accentGreen.opacity(0.02)],
                    startPoint: .top, endPoint: .bottom
                )
            )
            .interpolationMethod(.catmullRom)

            LineMark(
                x: .value("Month", item.id, unit: .month),
                y: .value("Outflow", Double(item.totalDebit) / 100.0)
            )
            .foregroundStyle(AppColors.accentGreen)
            .lineStyle(StrokeStyle(lineWidth: 2))
            .interpolationMethod(.catmullRom)
        }
        .frame(height: 160)
        .chartXAxis {
            AxisMarks(format: .dateTime.month(.abbreviated))
        }
        .chartYAxis(.hidden)
        .chartPlotStyle { area in
            area.background(Color.clear)
        }
    }

    private func changeChip(_ change: Double) -> some View {
        let positive = change > 0
        return HStack(spacing: 2) {
            Image(systemName: positive ? "arrow.up" : "arrow.down")
                .font(AppTypography.captionSmSemibold)
            FDSLabel(String(format: "%.1f%%", abs(change)))
                .font(AppTypography.captionSmSemibold)
        }
        .foregroundStyle(positive ? AppColors.danger : AppColors.accentGreen)
    }

    private func chip(_ text: String, color: Color, textColor: Color) -> some View {
        FDSLabel(text)
            .font(AppTypography.captionSmSemibold)
            .tracking(0.5)
            .foregroundStyle(textColor)
            .padding(.horizontal, AppSpacing.sm)
            .padding(.vertical, 4)
            .background(color)
            .cornerRadius(6)
    }
}

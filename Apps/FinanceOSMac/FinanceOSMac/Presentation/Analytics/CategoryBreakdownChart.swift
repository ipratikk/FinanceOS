import Charts
import FinanceCore
import FinanceUI
import SwiftUI

struct CategoryBreakdownChart: View {
    let items: [CategorySpendSummary]
    let currencyCode: String

    private var topItems: [CategorySpendSummary] {
        let top = Array(items.prefix(8))
        guard items.count > 8 else { return top }
        let otherTotal = items.dropFirst(8).reduce(0) { $0 + $1.totalDebit }
        let otherCount = items.dropFirst(8).reduce(0) { $0 + $1.transactionCount }
        let grandTotal = items.reduce(0) { $0 + $1.totalDebit }
        let otherPct = grandTotal > 0 ? Double(otherTotal) / Double(grandTotal) * 100 : 0
        let other = CategorySpendSummary(
            id: "other", displayName: "Other",
            totalDebit: otherTotal, percentage: otherPct, transactionCount: otherCount
        )
        return top + [other]
    }

    private var grandTotal: Int64 {
        items.reduce(0) { $0 + $1.totalDebit }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            donutChart
            Divider().opacity(0.3)
            categoryList
        }
    }

    private var donutChart: some View {
        ZStack {
            Chart(topItems) { item in
                SectorMark(
                    angle: .value("Spend", item.totalDebit),
                    innerRadius: .ratio(0.58),
                    angularInset: 2.5
                )
                .foregroundStyle(color(for: item.id))
                .cornerRadius(5)
            }
            .frame(height: 220)
            .chartLegend(.hidden)

            VStack(spacing: 2) {
                FDSLabel("Total Spend")
                    .font(AppTypography.captionSmMedium)
                    .foregroundStyle(AppColors.Text.secondary)
                FDSLabel(formatAmount(grandTotal))
                    .font(AppTypography.bodyMdSemibold)
                    .foregroundStyle(AppColors.Text.primary)
            }
        }
        .padding(.horizontal, AppSpacing.xl)
    }

    private var categoryList: some View {
        VStack(spacing: 0) {
            ForEach(Array(topItems.enumerated()), id: \.element.id) { index, item in
                categoryRow(item)
                if index < topItems.count - 1 {
                    Divider().opacity(0.25).padding(.leading, 44)
                }
            }
        }
    }

    private func categoryRow(_ item: CategorySpendSummary) -> some View {
        HStack(spacing: AppSpacing.md) {
            ZStack {
                Circle()
                    .fill(color(for: item.id).opacity(0.15))
                    .frame(width: 32, height: 32)
                Image(systemName: symbol(for: item.id))
                    .font(AppTypography.captionLg)
                    .foregroundStyle(color(for: item.id))
            }

            VStack(alignment: .leading, spacing: 2) {
                FDSLabel(item.displayName)
                    .font(AppTypography.bodySmMedium)
                    .foregroundStyle(AppColors.Text.primary)
                FDSLabel("\(item.transactionCount) transactions")
                    .font(AppTypography.captionSm)
                    .foregroundStyle(AppColors.Text.tertiary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                FDSLabel(formatAmount(item.totalDebit))
                    .font(AppTypography.bodySmSemibold)
                    .foregroundStyle(AppColors.Text.primary)
                    .monospacedDigit()
                FDSLabel(String(format: "%.1f%%", item.percentage))
                    .font(AppTypography.captionSm)
                    .foregroundStyle(AppColors.Text.tertiary)
            }
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.sm)
    }

    private func formatAmount(_ minorUnits: Int64) -> String {
        MoneyFormatting.formatRounded(minorUnits: minorUnits)
    }

    private func symbol(for categoryId: String) -> String {
        CategorySymbol.symbol(for: categoryId)
    }

    private func color(for categoryId: String) -> Color {
        categoryId == "other" ? .gray : CategorySymbol.color(for: categoryId)
    }
}

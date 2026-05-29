import FinanceCore
import FinanceIntelligence
import FinanceUI
import SwiftUI

// MARK: - Recent Activity

extension DashboardView {
    func recentActivityCard(_ viewModel: DashboardViewModel) -> some View {
        FDSCard(padded: false) {
            VStack(alignment: .leading, spacing: 0) {
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

                HStack {
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

                ForEach(Array(viewModel.recentTransactions.enumerated()), id: \.element.id) { idx, row in
                    activityRow(row)
                    if idx < viewModel.recentTransactions.count - 1 {
                        Divider().padding(.horizontal, 20).opacity(0.08)
                    }
                }
            }
            .padding(.bottom, 8)
        }
    }

    private func activityRow(_ row: TransactionRow) -> some View {
        HStack(spacing: 0) {
            HStack(spacing: 10) {
                Circle()
                    .fill(AppColors.Fill.secondary)
                    .frame(width: 30, height: 30)
                    .overlay {
                        Image(systemName: CategorySymbol.symbol(for: row.categoryId))
                            .font(AppTypography.captionSmSemibold)
                            .foregroundStyle(AppColors.Text.secondary)
                    }
                FDSLabel(row.displayTitle)
                    .font(AppTypography.bodySmMedium)
                    .foregroundStyle(AppColors.Text.primary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            let catName = CategoryTaxonomy.current.category(forId: row.categoryId ?? "")?.displayName ?? "Transfer"
            FDSLabel(catName)
                .font(AppTypography.captionLg)
                .foregroundStyle(AppColors.Text.tertiary)
                .frame(width: 110, alignment: .leading)
                .lineLimit(1)

            FDSLabel(row.amountText)
                .font(AppTypography.bodySmSemibold)
                .monospacedDigit()
                .foregroundStyle(row.transactionType == .debit ? AppColors.danger : AppColors.success)
                .frame(width: 100, alignment: .trailing)
                .lineLimit(1)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }
}

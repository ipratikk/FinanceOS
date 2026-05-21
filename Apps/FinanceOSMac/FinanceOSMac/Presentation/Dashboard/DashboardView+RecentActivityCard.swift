import FinanceCore
import FinanceUI
import SwiftUI

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
                    activityRow(txn)
                    if idx < txns.count - 1 {
                        Divider().padding(.horizontal, 20).opacity(0.08)
                    }
                }
            }
            .padding(.bottom, 8)
        }
    }

    private func activityRow(_ txn: FinanceCore.Transaction) -> some View {
        HStack(spacing: 0) {
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

    private func categorySymbol(for description: String) -> String {
        let lower = description.lowercased()
        if lower.contains("salary") || lower.contains("credit") {
            return "arrow.down.left.circle.fill"
        }
        if lower.contains("food") || lower.contains("zomato") { return "fork.knife" }
        if lower.contains("netflix") || lower.contains("spotify") { return "play.tv.fill" }
        if lower.contains("amazon") || lower.contains("flipkart") { return "bag.fill" }
        if lower.contains("apple") { return "laptopcomputer" }
        if lower.contains("uber") || lower.contains("ola") { return "car.fill" }
        return "creditcard.fill"
    }
}

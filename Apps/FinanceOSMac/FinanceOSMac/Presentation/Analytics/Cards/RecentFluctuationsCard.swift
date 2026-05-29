import FinanceCore
import FinanceUI
import SwiftUI

struct RecentFluctuationsCard: View {
    let transactions: [FinanceCore.Transaction]

    var body: some View {
        FDSCard(cornerRadius: 16, padded: false) {
            VStack(alignment: .leading, spacing: 0) {
                headerRow
                Divider().opacity(0.12)
                if transactions.isEmpty {
                    emptyState
                } else {
                    fluctuationList
                }
            }
        }
    }

    private var headerRow: some View {
        HStack {
            FDSLabel("Recent Fluctuations")
                .font(AppTypography.headingSmall)
                .foregroundStyle(AppColors.Text.primary)
            Spacer()
            Button(action: {}, label: {
                FDSLabel("Download CSV")
                    .font(AppTypography.captionSmSemibold)
                    .foregroundStyle(AppColors.accentGreen)
            })
            .buttonStyle(.plain)
        }
        .padding(AppSpacing.md)
    }

    private var fluctuationList: some View {
        VStack(spacing: 0) {
            ForEach(Array(transactions.enumerated()), id: \.element.id) { idx, txn in
                fluctuationRow(txn)
                if idx < transactions.count - 1 {
                    Divider().opacity(0.12).padding(.horizontal, AppSpacing.md)
                }
            }
        }
        .padding(.bottom, AppSpacing.sm)
    }

    private func fluctuationRow(_ txn: FinanceCore.Transaction) -> some View {
        HStack(spacing: AppSpacing.md) {
            fluctuationIcon(txn)
            VStack(alignment: .leading, spacing: 2) {
                FDSLabel(txn.merchantName ?? txn.description)
                    .font(AppTypography.bodySmMedium)
                    .foregroundStyle(AppColors.Text.primary)
                    .lineLimit(1)
                FDSLabel("\(formatDate(txn.postedAt)) · \(txn.currencyCode)")
                    .font(AppTypography.captionSm)
                    .foregroundStyle(AppColors.Text.tertiary)
            }
            Spacer()
            FDSLabel(formatAmount(txn))
                .font(AppTypography.bodySmSemibold)
                .foregroundStyle(txn.transactionType == .debit ? AppColors.Text.primary : AppColors.accentGreen)
                .monospacedDigit()
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.sm)
    }

    private func fluctuationIcon(_ txn: FinanceCore.Transaction) -> some View {
        let isDebit = txn.transactionType == .debit
        let color: Color = isDebit ? AppColors.danger : AppColors.accentGreen
        return ZStack {
            Circle()
                .fill(color.opacity(0.12))
                .frame(width: 36, height: 36)
            Image(systemName: isDebit ? "arrow.up.right" : "arrow.down.left")
                .font(AppTypography.captionLgSemibold)
                .foregroundStyle(color)
        }
    }

    private var emptyState: some View {
        FDSLabel("No notable fluctuations detected yet.")
            .font(AppTypography.bodySm)
            .foregroundStyle(AppColors.Text.tertiary)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(AppSpacing.xl)
    }

    private func formatDate(_ date: Date) -> String {
        FormatterCache.dayMonthCommaYear.string(from: date)
    }

    private func formatAmount(_ txn: FinanceCore.Transaction) -> String {
        MoneyFormatting.formatWithSign(minorUnits: txn.amountMinorUnits, isDebit: txn.transactionType == .debit)
    }
}

import FinanceCore
import FinanceUI
import SwiftUI

struct RecentFluctuationsCard: View {
    let transactions: [FluctuationRow]

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
            ForEach(Array(transactions.enumerated()), id: \.element.id) { idx, row in
                fluctuationRow(row)
                if idx < transactions.count - 1 {
                    Divider().opacity(0.12).padding(.horizontal, AppSpacing.md)
                }
            }
        }
        .padding(.bottom, AppSpacing.sm)
    }

    private func fluctuationRow(_ row: FluctuationRow) -> some View {
        HStack(spacing: AppSpacing.md) {
            fluctuationIcon(isDebit: row.isDebit)
            VStack(alignment: .leading, spacing: 2) {
                FDSLabel(row.merchantName)
                    .font(AppTypography.bodySmMedium)
                    .foregroundStyle(AppColors.Text.primary)
                    .lineLimit(1)
                FDSLabel("\(row.dateText) · \(row.currencyCode)")
                    .font(AppTypography.captionSm)
                    .foregroundStyle(AppColors.Text.tertiary)
            }
            Spacer()
            FDSLabel(row.amountText)
                .font(AppTypography.bodySmSemibold)
                .foregroundStyle(row.isDebit ? AppColors.Text.primary : AppColors.accentGreen)
                .monospacedDigit()
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.sm)
    }

    private func fluctuationIcon(isDebit: Bool) -> some View {
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
}

import FinanceCore
import FinanceUI
import SwiftUI

struct TransactionDetailView: View {
    let row: TransactionRow
    @Environment(\.dismiss) var dismiss

    var body: some View {
        FDSSheet(
            title: "Transaction Details",
            subtitle: row.title,
            onDismiss: { dismiss() },
            content: {
                VStack(alignment: .leading, spacing: 20) {
                    heroAmount

                    FDSCard(cornerRadius: 12, padded: false) {
                        VStack(spacing: 0) {
                            detailRow(label: "Merchant", value: row.title)
                            Divider().opacity(AppColors.Opacity.low).padding(.vertical, 8)
                            detailRow(label: "Source", value: row.subtitle)
                            Divider().opacity(AppColors.Opacity.low).padding(.vertical, 8)
                            detailRow(label: "Date", value: formatDate(row.postedAt))
                            Divider().opacity(AppColors.Opacity.low).padding(.vertical, 8)
                            detailRow(
                                label: "Type",
                                value: row.transactionType == .debit ? "Debit" : "Credit"
                            )
                        }
                    }
                }
            }
        )
    }

    private var heroAmount: some View {
        VStack(alignment: .center, spacing: 8) {
            FDSLabel(row.transactionType == .debit ? "DEBITED" : "CREDITED")
                .font(AppTypography.captionSmSemibold)
                .tracking(0.2)
                .foregroundColor(AppColors.Text.secondary)

            HStack(alignment: .firstTextBaseline, spacing: 8) {
                FDSLabel(row.amountText)
                    .font(AppTypography.headingXL)
                    .monospacedDigit()
                    .foregroundColor(row.transactionType == .debit ? AppColors.System.red : AppColors.System
                        .green)

                Image(systemName: row.transactionType == .debit ? "arrow.up.right" : "arrow.down.left")
                    .font(AppTypography.headingMd)
                    .foregroundColor(row.transactionType == .debit ? AppColors.System.red : AppColors.System
                        .green)
            }
            .frame(maxWidth: .infinity, alignment: .center)
        }
    }

    private func detailRow(label: String, value: String) -> some View {
        HStack {
            FDSLabel(label.uppercased())
                .font(AppTypography.captionSmSemibold)
                .tracking(0.2)
                .foregroundColor(AppColors.Text.secondary)
            Spacer()
            FDSLabel(value)
                .font(AppTypography.captionSmMedium)
                .foregroundColor(AppColors.Text.primary)
                .multilineTextAlignment(.trailing)
        }
        .padding(AppSpacing.xs)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

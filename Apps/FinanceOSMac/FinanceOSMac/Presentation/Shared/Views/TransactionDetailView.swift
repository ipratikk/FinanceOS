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
                            Divider().opacity(DesignTokens.Opacity.low).padding(.vertical, 8)
                            detailRow(label: "Source", value: row.subtitle)
                            Divider().opacity(DesignTokens.Opacity.low).padding(.vertical, 8)
                            detailRow(label: "Date", value: formatDate(row.postedAt))
                            Divider().opacity(DesignTokens.Opacity.low).padding(.vertical, 8)
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
            Text(row.transactionType == .debit ? "DEBITED" : "CREDITED")
                .font(.system(size: 11, weight: .semibold))
                .tracking(0.2)
                .foregroundColor(DesignTokens.Text.secondary)

            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(row.amountText)
                    .font(.system(size: 40, weight: .semibold, design: .default))
                    .monospacedDigit()
                    .foregroundColor(row.transactionType == .debit ? DesignTokens.System.red : DesignTokens.System
                        .green)

                Image(systemName: row.transactionType == .debit ? "arrow.up.right" : "arrow.down.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(row.transactionType == .debit ? DesignTokens.System.red : DesignTokens.System
                        .green)
            }
            .frame(maxWidth: .infinity, alignment: .center)
        }
    }

    private func detailRow(label: String, value: String) -> some View {
        HStack {
            Text(label.uppercased())
                .font(.system(size: 10, weight: .semibold))
                .tracking(0.2)
                .foregroundColor(DesignTokens.Text.secondary)
            Spacer()
            Text(value)
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(DesignTokens.Text.primary)
                .multilineTextAlignment(.trailing)
        }
        .padding(12)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

import FinanceCore
import FinanceUI
import SwiftUI

struct TransactionDetailView: View {
    let row: TransactionRow
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider().opacity(0.3)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: AppSpacing.xl) {
                    heroAmount
                    detailsSection
                }
                .padding(AppSpacing.xl)
            }
        }
        .frame(width: 480, height: 560)
        .background(AppColors.base)
    }

    private var header: some View {
        HStack(spacing: AppSpacing.compact) {
            FDSMerchantAvatar(
                name: row.title,
                symbol: row.transactionType == .debit ? "arrow.up.right.circle.fill" : "arrow.down.left.circle.fill",
                size: 32
            )
            VStack(alignment: .leading, spacing: 0) {
                Text("Transaction")
                    .bodyMedium()
                Text(row.title)
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
            }
            Spacer()
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .captionSmall()
                    .foregroundStyle(.secondary)
                    .frame(width: 22, height: 22)
                    .background(Circle().fill(.ultraThinMaterial))
            }
            .buttonStyle(.plain)
        }
        .padding(AppSpacing.md)
    }

    private var heroAmount: some View {
        VStack(alignment: .leading, spacing: AppSpacing.tight) {
            Text(row.transactionType == .debit ? "DEBITED" : "CREDITED")
                .font(.system(size: 10, weight: .semibold))
                .tracking(0.6)
                .foregroundStyle(.tertiary)

            HStack(alignment: .firstTextBaseline, spacing: AppSpacing.compact) {
                Text(row.amountText)
                    .font(.system(size: 36, weight: .bold, design: .rounded).monospacedDigit())
                    .foregroundStyle(row.transactionType == .debit ? AppColors.debit : AppColors.credit)

                Image(systemName: row.transactionType == .debit ? "arrow.up.right" : "arrow.down.left")
                    .bodyMedium()
                    .foregroundStyle(row.transactionType == .debit ? AppColors.debit : AppColors.credit)
            }
        }
    }

    private var detailsSection: some View {
        FDSGlassSurface(cornerRadius: AppRadius.lg) {
            VStack(spacing: 0) {
                detailRow(label: "Merchant", value: row.title)
                Divider().opacity(0.3).padding(.vertical, AppSpacing.compact)
                detailRow(label: "Source", value: row.subtitle)
                Divider().opacity(0.3).padding(.vertical, AppSpacing.compact)
                detailRow(label: "Date", value: formatDate(row.postedAt))
                Divider().opacity(0.3).padding(.vertical, AppSpacing.compact)
                detailRow(
                    label: "Type",
                    value: row.transactionType == .debit ? "Debit" : "Credit"
                )
            }
        }
    }

    private func detailRow(label: String, value: String) -> some View {
        HStack {
            Text(label.uppercased())
                .font(.system(size: 10, weight: .semibold))
                .tracking(0.6)
                .foregroundStyle(.tertiary)
            Spacer()
            Text(value)
                .bodySmall()
                .foregroundStyle(.primary)
                .multilineTextAlignment(.trailing)
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

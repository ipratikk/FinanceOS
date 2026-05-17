import FinanceCore
import SwiftUI

struct TransactionDetailView: View {
    let row: TransactionRow
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Transaction Details")
                        .headingMedium()
                    Spacer()
                    Button(action: { dismiss() }, label: {
                        Image(systemName: "xmark.circle.fill")
                            .headingSmall()
                            .foregroundColor(.gray)
                    })
                    .accessibilityLabel("Close")
                }
                .padding(AppSpacing.md)
                .background(AppColors.base)

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Amount")
                                .captionLarge()

                            HStack(spacing: 8) {
                                Text(row.amountText)
                                    .font(.system(size: 14, weight: .semibold, design: .monospaced))
                                    .foregroundColor(row.transactionType == .debit ? AppColors.debit : AppColors.credit)

                                Text(row.transactionType == .debit ? "Dr" : "Cr")
                                    .labelSmall()
                                    .padding(.vertical, 2)
                                    .padding(.horizontal, 6)
                                    .background(row.transactionType == .debit ? AppColors.debit
                                        .opacity(0.15) : AppColors.credit.opacity(0.15))
                                    .foregroundColor(row.transactionType == .debit ? AppColors.debit : AppColors.credit)
                                    .cornerRadius(AppRadius.sm)

                                Spacer()
                            }
                        }
                        .padding(AppSpacing.sm)
                        .background(AppColors.surface)
                        .cornerRadius(AppRadius.md)

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Description")
                                .captionLarge()
                                .foregroundColor(.gray)

                            Text(row.title)
                                .bodyLarge()
                        }
                        .padding(AppSpacing.sm)
                        .background(AppColors.surface)
                        .cornerRadius(AppRadius.md)

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Source")
                                .captionLarge()
                                .foregroundColor(.gray)

                            Text(row.subtitle)
                                .bodyLarge()
                        }
                        .padding(AppSpacing.sm)
                        .background(AppColors.surface)
                        .cornerRadius(AppRadius.md)

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Date")
                                .captionLarge()
                                .foregroundColor(.gray)

                            Text(formatDate(row.postedAt))
                                .bodyLarge()
                        }
                        .padding(AppSpacing.sm)
                        .background(AppColors.surface)
                        .cornerRadius(AppRadius.md)

                        Spacer()
                    }
                    .padding(AppSpacing.md)
                }
            }
            .background(AppColors.base)
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

#Preview {
    TransactionDetailView(
        row: TransactionRow(
            id: UUID(),
            title: "Coffee",
            subtitle: "Chase Checking",
            amountText: "-USD 5.00",
            transactionType: .debit,
            postedAt: Date()
        )
    )
}

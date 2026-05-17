import FinanceCore
import FinanceUI
import SwiftUI

struct TransactionDetailView: View {
    let row: TransactionRow
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            headerView
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        FDSLabel("Amount", style: .subheading)

                        HStack(spacing: 8) {
                            FDSAmount(row.amountText, type: row.transactionType == .debit ? .debit : .credit)

                            FDSText(
                                row.transactionType == .debit ? "Dr" : "Cr",
                                style: .labelSmall,
                                color: row.transactionType == .debit ? .debit : .credit
                            )
                            .padding(.vertical, 2)
                            .padding(.horizontal, 6)
                            .background(row.transactionType == .debit ? AppColors.debit
                                .opacity(0.15) : AppColors.credit.opacity(0.15))
                            .cornerRadius(AppRadius.sm)

                            Spacer()
                        }
                    }
                    .padding(AppSpacing.sm)
                    .background(AppColors.surface)
                    .cornerRadius(AppRadius.md)

                    VStack(alignment: .leading, spacing: 8) {
                        FDSLabel("Description", style: .subheading)
                        FDSText(row.title, style: .bodyLarge, color: .primary)
                    }
                    .padding(AppSpacing.sm)
                    .background(AppColors.surface)
                    .cornerRadius(AppRadius.md)

                    VStack(alignment: .leading, spacing: 8) {
                        FDSLabel("Source", style: .subheading)
                        FDSText(row.subtitle, style: .bodyLarge, color: .primary)
                    }
                    .padding(AppSpacing.sm)
                    .background(AppColors.surface)
                    .cornerRadius(AppRadius.md)

                    VStack(alignment: .leading, spacing: 8) {
                        FDSLabel("Date", style: .subheading)
                        FDSText(formatDate(row.postedAt), style: .bodyLarge, color: .primary)
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

    var headerView: some View {
        HStack {
            FDSText("Transaction Details", style: .headingMedium)
            Spacer()
            Button(action: { dismiss() }, label: {
                Image(systemName: "xmark.circle.fill").headingSmall().foregroundColor(.gray)
            })
            .accessibilityLabel("Close")
        }
        .padding(AppSpacing.md)
        .background(AppColors.base)
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

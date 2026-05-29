import FinanceCore
import FinanceIntelligence
import FinanceUI
import SwiftUI

struct TransactionDetailView: View {
    let row: TransactionRow
    var onCorrected: ((UUID, String) -> Void)?
    @Environment(\.dismiss) var dismiss
    @Environment(\.transactionIntelligence) private var intelligence
    @State private var showCategoryPicker = false

    var body: some View {
        FDSSheet(
            title: "Transaction Details",
            subtitle: row.displayTitle,
            onDismiss: { dismiss() },
            content: {
                VStack(alignment: .leading, spacing: 20) {
                    heroAmount
                    detailCard
                }
            }
        )
        .sheet(isPresented: $showCategoryPicker) {
            if let txn = row.sourceTransaction {
                CategoryPickerView(
                    source: txn,
                    currentCategoryId: row.categoryId,
                    currentMerchant: row.merchantName,
                    previousPrediction: nil,
                    onCorrected: onCorrected
                )
            }
        }
    }

    private var detailCard: some View {
        FDSCard(cornerRadius: 12, padded: false) {
            VStack(spacing: 0) {
                if let merchant = row.merchantName, merchant != row.title {
                    detailRow(label: "Merchant", value: merchant)
                    Divider().opacity(AppColors.Opacity.low).padding(.vertical, 8)
                }
                detailRow(label: "Description", value: row.title)
                Divider().opacity(AppColors.Opacity.low).padding(.vertical, 8)
                detailRow(label: "Source", value: row.subtitle)
                Divider().opacity(AppColors.Opacity.low).padding(.vertical, 8)
                detailRow(label: "Date", value: formatDate(row.postedAt))
                Divider().opacity(AppColors.Opacity.low).padding(.vertical, 8)
                detailRow(label: "Type", value: row.transactionType == .debit ? "Debit" : "Credit")
                if let categoryId = row.categoryId {
                    Divider().opacity(AppColors.Opacity.low).padding(.vertical, 8)
                    categoryRow(categoryId: categoryId)
                }
            }
        }
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
                    .foregroundColor(row.transactionType == .debit ? AppColors.System.red : AppColors.System.green)

                Image(systemName: row.transactionType == .debit ? "arrow.up.right" : "arrow.down.left")
                    .font(AppTypography.headingMd)
                    .foregroundColor(row.transactionType == .debit ? AppColors.System.red : AppColors.System.green)
            }
            .frame(maxWidth: .infinity, alignment: .center)
        }
    }

    private func categoryRow(categoryId: String) -> some View {
        HStack {
            HStack(spacing: AppSpacing.compact) {
                Image(systemName: CategorySymbol.symbol(for: categoryId))
                    .foregroundStyle(CategorySymbol.color(for: categoryId))
                    .font(AppTypography.captionLg)

                FDSLabel(categoryId.capitalized)
                    .font(AppTypography.captionSmSemibold)
                    .tracking(0.2)
                    .foregroundColor(AppColors.Text.secondary)
            }

            Spacer()

            HStack(spacing: AppSpacing.compact) {
                if row.isUserCorrected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .font(AppTypography.captionSm)
                }

                if intelligence != nil, row.sourceTransaction != nil {
                    Button(action: { showCategoryPicker = true }, label: {
                        FDSLabel("Change")
                            .font(AppTypography.captionSmMedium)
                            .foregroundStyle(AppColors.accentGold)
                    })
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(AppSpacing.xs)
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
        FormatterCache.formatDateTime(date)
    }
}

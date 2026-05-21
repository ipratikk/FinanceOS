import FinanceCore
import FinanceUI
import SwiftUI

struct BankEditView: View {
    let bank: Bank
    let context: BankEditContext
    @Environment(\.dismiss) var dismiss
    @State private var showDeleteConfirm = false

    init(bank: Bank, context: BankEditContext) {
        self.bank = bank
        self.context = context
    }

    var body: some View {
        FDSSheet(
            title: "Bank Details",
            subtitle: bank.name,
            onDismiss: { dismiss() },
            content: {
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    FDSCard(padded: false) {
                        VStack(alignment: .leading, spacing: AppSpacing.xs) {
                            FDSLabel("BANK INFORMATION")
                                .font(AppTypography.captionSmSemibold)
                                .tracking(0.2)
                                .foregroundColor(AppColors.Text.secondary)

                            infoRow("Bank Name", value: bank.name)
                            Divider().opacity(AppColors.Opacity.low)
                            infoRow("Provider Type", value: bank.providerType.rawValue.capitalized)
                        }
                        .padding(AppSpacing.xs)
                    }

                    FDSCard(padded: false) {
                        FDSLiquidButton("Delete Bank", symbol: "trash.fill", variant: .danger) {
                            showDeleteConfirm = true
                        }
                        .padding(AppSpacing.xs)
                    }
                }
            }
        )
        .alert("Delete Bank?", isPresented: $showDeleteConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                Task {
                    await context.deleteBank(id: bank.id)
                    if context.error == nil { dismiss() }
                }
            }
        } message: {
            FDSLabel("This will permanently delete this bank and all associated accounts, cards, and transactions.")
        }
        .alert("Error", isPresented: Binding(
            get: { context.error != nil },
            set: { if !$0 { context.clearError() } }
        )) {
            Button("OK") { context.clearError() }
        } message: {
            if let error = context.error {
                FDSLabel(error)
            }
        }
    }

    private func infoRow(_ label: String, value: String) -> some View {
        HStack {
            FDSLabel(label.uppercased())
                .font(AppTypography.captionSmSemibold)
                .tracking(0.2)
                .foregroundColor(AppColors.Text.secondary)
            Spacer()
            FDSLabel(value)
                .font(AppTypography.captionSmMedium)
                .foregroundColor(AppColors.Text.primary)
        }
        .padding(AppSpacing.xs)
    }
}

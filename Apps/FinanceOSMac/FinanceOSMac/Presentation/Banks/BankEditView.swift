import FinanceCore
import FinanceUI
import SwiftUI

struct BankEditView: View {
    let bank: Bank
    let context: BankEditContext
    @Environment(\.dismiss) var dismiss
    @State private var showDeleteConfirm = false

    var body: some View {
        VStack(spacing: 0) {
            headerBar
            scrollContent
        }
        .background(AppColors.base)
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

    private var headerBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                FDSLabel("Bank Details")
                    .font(AppTypography.headingLg)
                    .foregroundStyle(AppColors.Text.primary)
                FDSLabel(bank.name)
                    .font(AppTypography.captionSm)
                    .foregroundStyle(AppColors.Text.secondary)
            }
            Spacer()
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(AppTypography.headingSmall)
                    .foregroundStyle(AppColors.Text.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(AppSpacing.md)
        .background(AppColors.base)
    }

    private var scrollContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                infoSurface
                dangerZoneSurface
            }
            .padding(AppSpacing.md)
        }
    }

    private var infoSurface: some View {
        FDSGlassSurface(cornerRadius: AppRadius.lg) {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                FDSLabel("BANK INFORMATION")
                    .font(AppTypography.headingSmall)
                    .foregroundStyle(AppColors.Text.primary)
                infoRow("Bank Name", value: bank.name)
                Divider().opacity(AppColors.Opacity.low)
                infoRow("Provider Type", value: bank.providerType.rawValue.capitalized)
            }
        }
    }

    private var dangerZoneSurface: some View {
        FDSGlassSurface(cornerRadius: AppRadius.lg) {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                FDSLabel("DANGER ZONE")
                    .font(AppTypography.headingSmall)
                    .foregroundStyle(AppColors.Text.primary)
                FDSLiquidButton("Delete Bank", leadingIcon: "trash.fill", variant: .danger) {
                    showDeleteConfirm = true
                }
            }
        }
    }

    private func infoRow(_ label: String, value: String) -> some View {
        HStack {
            FDSLabel(label)
                .font(AppTypography.captionSm)
                .foregroundStyle(AppColors.Text.secondary)
            Spacer()
            FDSLabel(value)
                .font(AppTypography.captionSm)
                .foregroundStyle(AppColors.Text.primary)
        }
    }
}

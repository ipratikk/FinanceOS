import FinanceCore
import FinanceUI
import SwiftUI

struct BankEditView: View {
    let bank: Bank
    let context: BankEditContext
    @State private var selectedBank: Banks?
    @Environment(\.dismiss) var dismiss
    @State private var showDeleteConfirm = false

    init(bank: Bank, context: BankEditContext) {
        self.bank = bank
        self.context = context
        _selectedBank = State(initialValue: bank.bank)
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider().opacity(0.3)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: AppSpacing.xl) {
                    bankIdentitySection
                    deleteSection
                }
                .padding(AppSpacing.xl)
            }

            Divider().opacity(0.3)
            footer
        }
        .frame(width: 480, height: 520)
        .background(AppColors.base)
        .alert("Delete Bank?", isPresented: $showDeleteConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                Task {
                    await context.deleteBank(id: bank.id)
                    if context.deleteError == nil {
                        dismiss()
                    }
                }
            }
        } message: {
            Text("This will delete this bank and all associated cards, accounts, and transactions.")
        }
        .alert("Delete Failed", isPresented: Binding(
            get: { context.deleteError != nil },
            set: { if !$0 { context.clearError() } }
        )) {
            Button("OK") { context.clearError() }
        } message: {
            if let error = context.deleteError {
                Text(error)
            }
        }
    }

    private var header: some View {
        HStack(spacing: AppSpacing.compact) {
            FDSMerchantAvatar(name: bank.name, symbol: "building.columns.fill", size: 32)
            VStack(alignment: .leading, spacing: 0) {
                Text("Edit Bank")
                    .bodyMedium()
                Text(bank.name)
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
            }
            Spacer()
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .labelSmall()
                    .foregroundStyle(.secondary)
                    .frame(width: 22, height: 22)
                    .background(Circle().fill(.ultraThinMaterial))
            }
            .buttonStyle(.plain)
        }
        .padding(AppSpacing.md)
    }

    private var bankIdentitySection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            FDSSectionHeader("Bank Information")

            field("Bank") {
                let bankOptions = Banks.allCases.map { bankCase in
                    FDSPickerOption(
                        id: bankCase.rawValue,
                        value: bankCase,
                        title: bankCase.displayName,
                        imageName: bankCase.symbolAssetName
                    )
                }
                FDSPicker(
                    selection: $selectedBank,
                    options: bankOptions,
                    variant: .symbolText,
                    placeholder: "Select bank"
                )
            }
        }
    }

    private var deleteSection: some View {
        Button(action: { showDeleteConfirm = true }) {
            HStack(spacing: AppSpacing.compact) {
                Image(systemName: "trash.fill")
                    .font(.system(size: 12, weight: .semibold))
                Text("Delete Bank")
                    .caption()
                Spacer()
            }
            .foregroundStyle(AppColors.debit)
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.compact)
            .background {
                RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
                    .fill(AppColors.debit.opacity(0.12))
            }
        }
        .buttonStyle(.plain)
    }

    private var footer: some View {
        HStack(spacing: AppSpacing.compact) {
            FDSLiquidButton("Cancel", variant: .subtle) { dismiss() }
            Spacer()
            FDSLiquidButton("Save", variant: .primary) {
                guard let bankSelection = selectedBank else { return }
                Task {
                    let updated = Bank(id: bank.id, bank: bankSelection)
                    await context.updateBank(updated)
                    if context.deleteError == nil {
                        dismiss()
                    }
                }
            }
        }
        .padding(AppSpacing.md)
    }

    private func field(
        _ label: String,
        @ViewBuilder content: () -> some View
    ) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.tight) {
            Text(label.uppercased())
                .font(.system(size: 10, weight: .semibold))
                .tracking(0.6)
                .foregroundStyle(.tertiary)
            content()
        }
    }
}

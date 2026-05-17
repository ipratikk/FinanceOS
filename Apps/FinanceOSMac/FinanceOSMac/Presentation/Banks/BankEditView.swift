import FinanceCore
import FinanceUI
import SwiftUI

struct BankEditView: View {
    let bank: Bank
    let context: BankEditContext
    @State private var name: String
    @State private var providerType: BankProviderType
    @Environment(\.dismiss) var dismiss
    @Environment(AppNavigator.self) private var navigator

    @State private var showDeleteConfirm = false

    init(bank: Bank, context: BankEditContext) {
        self.bank = bank
        self.context = context
        _name = State(initialValue: bank.name)
        _providerType = State(initialValue: bank.providerType)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                FDSLabel("Edit Bank", style: .headingMedium)
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

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        FDSLabel("Bank Information", style: .subheading)

                        VStack(spacing: 8) {
                            inputField("Name", text: $name)

                            VStack(alignment: .leading, spacing: 4) {
                                FDSLabel("Provider Type", style: .hint)
                                Picker("Type", selection: $providerType) {
                                    ForEach(BankProviderType.allCases, id: \.self) { type in
                                        Text(type.rawValue.capitalized).tag(type)
                                    }
                                }
                                .pickerStyle(.menu)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .padding(AppSpacing.xs)
                            .background(AppColors.surface2)
                            .cornerRadius(AppRadius.sm)
                        }
                    }
                    .padding(AppSpacing.sm)
                    .background(AppColors.surface)
                    .cornerRadius(AppRadius.md)

                    VStack(spacing: 8) {
                        Button(action: { showDeleteConfirm = true }, label: {
                            HStack {
                                Image(systemName: "trash.fill")
                                    .labelSmall()
                                FDSLabel("Delete Bank", style: .bodyLarge)
                                Spacer()
                            }
                        })
                        .foregroundColor(AppColors.debit)
                        .padding(AppSpacing.sm)
                        .frame(maxWidth: .infinity)
                        .background(AppColors.debit.opacity(0.1))
                        .cornerRadius(AppRadius.md)
                    }
                }
                .padding(AppSpacing.md)
            }

            Divider()

            HStack(spacing: 12) {
                Button("Cancel", action: { dismiss() })
                    .foregroundColor(.gray)
                    .padding(AppSpacing.sm)
                    .background(AppColors.surface)
                    .cornerRadius(AppRadius.md)
                    .frame(maxWidth: .infinity)

                Button(action: {
                    Task {
                        let updated = Bank(
                            id: bank.id,
                            name: name,
                            providerType: providerType
                        )
                        await context.updateBank(updated)
                        if context.deleteError == nil {
                            dismiss()
                        }
                    }
                }, label: {
                    FDSLabel("Save", style: .monoAmount)
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.white)
                })
                .padding(AppSpacing.sm)
                .background(AppColors.accent)
                .cornerRadius(AppRadius.md)
            }
            .padding(AppSpacing.md)
        }
        .frame(maxHeight: .infinity, alignment: .topLeading)
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
            Text("This will delete this bank and all associated cards, " +
                "accounts, and transactions. This cannot be undone.")
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

    private func inputField(_ label: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            FDSLabel(label, style: .hint)
            FDSTextInput("", text: text, style: .bodyMedium)
                .padding(AppSpacing.xs)
                .background(AppColors.surface2)
                .cornerRadius(AppRadius.sm)
        }
    }
}

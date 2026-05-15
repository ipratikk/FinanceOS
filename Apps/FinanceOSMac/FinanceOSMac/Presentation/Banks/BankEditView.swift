import FinanceCore
import SwiftUI

struct BankEditView: View {
    let bank: Bank
    let viewModel: BanksViewModel
    @State private var name: String
    @State private var providerType: BankProviderType
    @Environment(\.dismiss) var dismiss

    @State private var showDeleteConfirm = false

    init(bank: Bank, viewModel: BanksViewModel) {
        self.bank = bank
        self.viewModel = viewModel
        _name = State(initialValue: bank.name)
        _providerType = State(initialValue: bank.providerType)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Edit Bank")
                    .headingMedium()
                Spacer()
                Button(action: { dismiss() }, label: {
                    Image(systemName: "xmark.circle.fill")
                        .headingSmall()
                        .foregroundColor(.gray)
                })
            }
            .padding(AppSpacing.md)
            .background(AppColors.base)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Bank Information")
                            .captionLarge()
                            .foregroundColor(.gray)

                        VStack(spacing: 8) {
                            inputField("Name", text: $name)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Provider Type")
                                    .labelSmall()
                                    .foregroundColor(.gray)
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
                                Text("Delete Bank")
                                    .bodyLarge()
                                Spacer()
                            }
                        })
                        .foregroundColor(.red)
                        .padding(AppSpacing.sm)
                        .frame(maxWidth: .infinity)
                        .background(Color.red.opacity(0.1))
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
                        await viewModel.updateBank(updated)
                        dismiss()
                    }
                }, label: {
                    Text("Save")
                        .monoAmount()
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
                    await viewModel.deleteBank(id: bank.id)
                    dismiss()
                }
            }
        } message: {
            Text("This will delete this bank and all associated cards, " +
                "accounts, and transactions. This cannot be undone.")
        }
    }

    private func inputField(_ label: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .labelSmall()
                .foregroundColor(.gray)
            TextField("", text: text)
                .caption()
                .padding(AppSpacing.xs)
                .background(AppColors.surface2)
                .cornerRadius(AppRadius.sm)
        }
    }
}

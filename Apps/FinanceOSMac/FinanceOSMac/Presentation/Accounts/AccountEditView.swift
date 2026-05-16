import FinanceCore
import SwiftUI

struct AccountEditView: View {
    let account: Ledger
    let viewModel: AccountsViewModel
    @State private var displayName: String
    @State private var last4: String
    @State private var ownerName: String
    @State private var accountType: String
    @State private var nickname: String
    @State private var bankId: UUID
    @Environment(\.dismiss) var dismiss

    @State private var showDeleteConfirm = false
    @State private var deleteErrorMessage: String?

    init(account: Ledger, viewModel: AccountsViewModel) {
        self.account = account
        self.viewModel = viewModel
        _displayName = State(initialValue: account.displayName)
        _last4 = State(initialValue: account.last4)
        _ownerName = State(initialValue: account.ownerName)
        _accountType = State(initialValue: account.accountType ?? "savings")
        _nickname = State(initialValue: account.nickname)
        _bankId = State(initialValue: account.bankId)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Edit Account")
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
                        Text("Account Information")
                            .captionLarge()
                            .foregroundColor(.gray)

                        VStack(spacing: 8) {
                            inputField("Account Name", text: $displayName)
                            inputField("Owner Name", text: $ownerName)
                            inputField("Last 4 Digits", text: $last4)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Account Type")
                                    .labelSmall()
                                    .foregroundColor(.gray)
                                Picker("Type", selection: $accountType) {
                                    ForEach(["savings", "checking", "credit"], id: \.self) { type in
                                        Text(type.capitalized).tag(type)
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

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Bank & Nickname")
                            .captionLarge()
                            .foregroundColor(.gray)

                        VStack(spacing: 8) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Bank")
                                    .labelSmall()
                                    .foregroundColor(.gray)
                                Picker("Bank", selection: $bankId) {
                                    ForEach(viewModel.banks) { bank in
                                        Text(bank.name).tag(bank.id)
                                    }
                                }
                                .pickerStyle(.menu)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .padding(AppSpacing.xs)
                            .background(AppColors.surface2)
                            .cornerRadius(AppRadius.sm)

                            inputField("Nickname (Optional)", text: $nickname)
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
                                Text("Delete Account")
                                    .bodyLarge()
                                Spacer()
                            }
                            .foregroundColor(.red)
                            .padding(AppSpacing.sm)
                            .frame(maxWidth: .infinity)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(AppRadius.md)
                        })
                    }
                }
                .padding(AppSpacing.md)
            }

            Divider()

            HStack(spacing: 12) {
                Button(action: { dismiss() }, label: {
                    Text("Cancel")
                        .bodyLarge()
                        .frame(maxWidth: .infinity)
                })
                .foregroundColor(.gray)
                .padding(AppSpacing.sm)
                .background(AppColors.surface)
                .cornerRadius(AppRadius.md)

                Button(action: {
                    Task {
                        let updated = Ledger(
                            id: account.id,
                            bankId: bankId,
                            kind: account.kind,
                            displayName: displayName,
                            last4: last4,
                            nickname: nickname,
                            ownerName: ownerName,
                            createdAt: account.createdAt,
                            accountType: accountType,
                            cardType: account.cardType,
                            cardProduct: account.cardProduct,
                            linkedLedgerId: account.linkedLedgerId,
                            isArchived: account.isArchived
                        )
                        await viewModel.updateAccount(updated)
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
        .alert("Delete Account?", isPresented: $showDeleteConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                Task {
                    await viewModel.deleteAccount(id: account.id)
                    if viewModel.deleteError == nil {
                        dismiss()
                    } else {
                        deleteErrorMessage = viewModel.deleteError
                    }
                }
            }
        } message: {
            Text("This will permanently delete this account and all associated transactions. This cannot be undone.")
        }
        .alert("Delete Failed", isPresented: .constant(deleteErrorMessage != nil)) {
            Button("OK") { deleteErrorMessage = nil }
        } message: {
            if let error = deleteErrorMessage {
                Text(error)
            }
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

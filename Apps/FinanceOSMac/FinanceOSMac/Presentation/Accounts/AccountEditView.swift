import FinanceCore
import SwiftUI

struct AccountEditView: View {
    let account: Account
    let viewModel: AccountsViewModel
    @State private var accountName: String
    @State private var accountLast4: String
    @State private var ownerName: String
    @State private var accountType: AccountType
    @State private var nickname: String
    @State private var bankId: UUID
    @Environment(\.dismiss) var dismiss

    @State private var showDeleteConfirm = false

    init(account: Account, viewModel: AccountsViewModel) {
        self.account = account
        self.viewModel = viewModel
        _accountName = State(initialValue: account.accountName)
        _accountLast4 = State(initialValue: account.accountLast4)
        _ownerName = State(initialValue: account.ownerName)
        _accountType = State(initialValue: account.accountType)
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
                            inputField("Account Name", text: $accountName)
                            inputField("Owner Name", text: $ownerName)
                            inputField("Last 4 Digits", text: $accountLast4)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Account Type")
                                    .labelSmall()
                                    .foregroundColor(.gray)
                                Picker("Type", selection: $accountType) {
                                    ForEach(AccountType.allCases, id: \.self) { type in
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
                        let updated = Account(
                            id: account.id,
                            bankId: bankId,
                            accountName: accountName,
                            accountLast4: accountLast4,
                            ownerName: ownerName,
                            accountType: accountType,
                            nickname: nickname
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
                    dismiss()
                }
            }
        } message: {
            Text("This will permanently delete this account and all associated transactions. This cannot be undone.")
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

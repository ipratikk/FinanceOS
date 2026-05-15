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
                    .font(.system(size: 18, weight: .semibold))
                Spacer()
                Button(action: { dismiss() }, label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                })
            }
            .padding(16)
            .background(Color(red: 0.051, green: 0.051, blue: 0.059))

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Account Information")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.gray)

                        VStack(spacing: 8) {
                            inputField("Account Name", text: $accountName)
                            inputField("Owner Name", text: $ownerName)
                            inputField("Last 4 Digits", text: $accountLast4)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Account Type")
                                    .font(.system(size: 12, weight: .regular))
                                    .foregroundColor(.gray)
                                Picker("Type", selection: $accountType) {
                                    ForEach(AccountType.allCases, id: \.self) { type in
                                        Text(type.rawValue.capitalized).tag(type)
                                    }
                                }
                                .pickerStyle(.menu)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .padding(10)
                            .background(Color(red: 0.110, green: 0.110, blue: 0.122))
                            .cornerRadius(6)
                        }
                    }
                    .padding(12)
                    .background(Color(red: 0.086, green: 0.086, blue: 0.098))
                    .cornerRadius(10)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Bank & Nickname")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.gray)

                        VStack(spacing: 8) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Bank")
                                    .font(.system(size: 12, weight: .regular))
                                    .foregroundColor(.gray)
                                Picker("Bank", selection: $bankId) {
                                    ForEach(viewModel.banks) { bank in
                                        Text(bank.name).tag(bank.id)
                                    }
                                }
                                .pickerStyle(.menu)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .padding(10)
                            .background(Color(red: 0.110, green: 0.110, blue: 0.122))
                            .cornerRadius(6)

                            inputField("Nickname (Optional)", text: $nickname)
                        }
                    }
                    .padding(12)
                    .background(Color(red: 0.086, green: 0.086, blue: 0.098))
                    .cornerRadius(10)

                    VStack(spacing: 8) {
                        Button(action: { showDeleteConfirm = true }, label: {
                            HStack {
                                Image(systemName: "trash.fill")
                                    .font(.system(size: 12))
                                Text("Delete Account")
                                    .font(.system(size: 14, weight: .medium))
                                Spacer()
                            }
                            .foregroundColor(.red)
                            .padding(12)
                            .frame(maxWidth: .infinity)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(8)
                        })
                    }
                }
                .padding(16)
            }

            Divider()

            HStack(spacing: 12) {
                Button(action: { dismiss() }, label: {
                    Text("Cancel")
                        .font(.system(size: 14, weight: .medium))
                        .frame(maxWidth: .infinity)
                })
                .foregroundColor(.gray)
                .padding(12)
                .background(Color(red: 0.086, green: 0.086, blue: 0.098))
                .cornerRadius(8)

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
                        .font(.system(size: 14, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.white)
                })
                .padding(12)
                .background(Color(red: 0.231, green: 0.510, blue: 0.980))
                .cornerRadius(8)
            }
            .padding(16)
        }
        .frame(maxHeight: .infinity, alignment: .topLeading)
        .background(Color(red: 0.051, green: 0.051, blue: 0.059))
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
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(.gray)
            TextField("", text: text)
                .font(.system(size: 13, weight: .regular))
                .padding(10)
                .background(Color(red: 0.110, green: 0.110, blue: 0.122))
                .cornerRadius(6)
        }
    }
}

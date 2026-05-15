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
    @State private var showConvertConfirm = false

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
        NavigationStack {
            Form {
                Section("Account Details") {
                    TextField("Account Name", text: $accountName)
                    TextField("Last 4 Digits", text: $accountLast4)
                    TextField("Owner Name", text: $ownerName)
                    Picker("Account Type", selection: $accountType) {
                        ForEach(AccountType.allCases, id: \.self) { type in
                            Text(type.rawValue.capitalized).tag(type)
                        }
                    }
                    TextField("Nickname", text: $nickname)
                }

                Section("Bank") {
                    Picker("Bank", selection: $bankId) {
                        ForEach(viewModel.banks) { bank in
                            Text(bank.name).tag(bank.id)
                        }
                    }
                }

                Section {
                    Button("Convert to Card") {
                        showConvertConfirm = true
                    }
                }

                Section {
                    Button("Delete Account", role: .destructive) {
                        showDeleteConfirm = true
                    }
                }
            }
            .navigationTitle("Edit Account")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
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
                        }
                    }
                }
            }
        }
        .alert("Convert to Card?", isPresented: $showConvertConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Convert", role: .destructive) {
                Task {
                    await viewModel.convertToCard(account)
                    dismiss()
                }
            }
        } message: {
            Text("This will convert this account to a card. All transactions will be reassigned.")
        }
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
}

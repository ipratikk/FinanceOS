import FinanceCore
import SwiftUI

struct AccountEditView: View {
    let account: Account
    let viewModel: AccountsViewModel
    @State private var name: String
    @State private var institutionID: UUID
    @Environment(\.dismiss) var dismiss

    @State private var showDeleteConfirm = false
    @State private var showConvertConfirm = false

    init(account: Account, viewModel: AccountsViewModel) {
        self.account = account
        self.viewModel = viewModel
        _name = State(initialValue: account.name)
        _institutionID = State(initialValue: account.institutionID)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Account Details") {
                    TextField("Name", text: $name)
                }

                Section("Institution") {
                    Picker("Institution", selection: $institutionID) {
                        ForEach(viewModel.institutions) { institution in
                            Text(institution.name).tag(institution.id)
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
                                institutionID: institutionID,
                                name: name
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

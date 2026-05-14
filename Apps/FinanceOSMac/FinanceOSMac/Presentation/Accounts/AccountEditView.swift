import FinanceCore
import SwiftUI

struct AccountEditView: View {
    @Bindable var account: Account
    let viewModel: AccountsViewModel
    @Environment(\.dismiss) var dismiss

    @State private var showDeleteConfirm = false
    @State private var showConvertConfirm = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Account Details") {
                    TextField("Name", text: $account.name)
                }

                Section("Institution") {
                    Picker("Institution", selection: $account.institutionID) {
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
                            await viewModel.updateAccount(account)
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
                }
            }
        } message: {
            Text("This will permanently delete this account and all associated transactions. This cannot be undone.")
        }
    }
}

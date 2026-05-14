import FinanceCore
import SwiftUI

struct CardEditView: View {
    let card: Card
    let viewModel: CardsViewModel
    @State private var name: String
    @State private var institutionID: UUID
    @State private var accountID: UUID?
    @Environment(\.dismiss) var dismiss

    @State private var showDeleteConfirm = false
    @State private var showConvertConfirm = false

    init(card: Card, viewModel: CardsViewModel) {
        self.card = card
        self.viewModel = viewModel
        _name = State(initialValue: card.name)
        _institutionID = State(initialValue: card.institutionID)
        _accountID = State(initialValue: card.accountID)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Card Details") {
                    TextField("Name", text: $name)
                }

                Section("Institution") {
                    Picker("Institution", selection: $institutionID) {
                        ForEach(viewModel.institutions) { institution in
                            Text(institution.name).tag(institution.id)
                        }
                    }
                }

                Section("Linked Account") {
                    Picker("Account", selection: $accountID) {
                        Text("None").tag(UUID?.none)
                        ForEach(viewModel.accounts) { account in
                            Text(account.name).tag(UUID?(account.id))
                        }
                    }
                }

                Section {
                    Button("Convert to Account") {
                        showConvertConfirm = true
                    }
                }

                Section {
                    Button("Delete Card", role: .destructive) {
                        showDeleteConfirm = true
                    }
                }
            }
            .navigationTitle("Edit Card")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        Task {
                            var updated = card
                            updated.name = name
                            updated.institutionID = institutionID
                            updated.accountID = accountID
                            await viewModel.updateCard(updated)
                        }
                    }
                }
            }
        }
        .alert("Convert to Account?", isPresented: $showConvertConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Convert", role: .destructive) {
                Task {
                    var updated = card
                    updated.name = name
                    updated.institutionID = institutionID
                    updated.accountID = accountID
                    await viewModel.convertToAccount(updated)
                    dismiss()
                }
            }
        } message: {
            Text("This will convert this card to an account. All transactions will be reassigned.")
        }
        .alert("Delete Card?", isPresented: $showDeleteConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                Task {
                    await viewModel.deleteCard(id: card.id)
                    dismiss()
                }
            }
        } message: {
            Text("This will permanently delete this card and all associated transactions. This cannot be undone.")
        }
    }
}

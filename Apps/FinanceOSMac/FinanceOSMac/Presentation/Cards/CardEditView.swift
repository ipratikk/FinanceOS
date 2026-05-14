import FinanceCore
import SwiftUI

struct CardEditView: View {
    let card: Card
    let viewModel: CardsViewModel
    @State private var editedCard: Card
    @Environment(\.dismiss) var dismiss

    @State private var showDeleteConfirm = false
    @State private var showConvertConfirm = false

    init(card: Card, viewModel: CardsViewModel) {
        self.card = card
        self.viewModel = viewModel
        _editedCard = State(initialValue: card)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Card Details") {
                    TextField("Name", text: $editedCard.name)
                }

                Section("Institution") {
                    Picker("Institution", selection: $editedCard.institutionID) {
                        ForEach(viewModel.institutions) { institution in
                            Text(institution.name).tag(institution.id)
                        }
                    }
                }

                Section("Linked Account") {
                    Picker("Account", selection: $editedCard.accountID) {
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
                            await viewModel.updateCard(editedCard)
                        }
                    }
                }
            }
        }
        .alert("Convert to Account?", isPresented: $showConvertConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Convert", role: .destructive) {
                Task {
                    await viewModel.convertToAccount(editedCard)
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
                    await viewModel.deleteCard(id: editedCard.id)
                    dismiss()
                }
            }
        } message: {
            Text("This will permanently delete this card and all associated transactions. This cannot be undone.")
        }
    }
}

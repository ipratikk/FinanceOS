import FinanceCore
import SwiftUI

struct CardEditView: View {
    @Bindable var card: Card
    let viewModel: CardsViewModel
    @Environment(\.dismiss) var dismiss

    @State private var showDeleteConfirm = false
    @State private var showConvertConfirm = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Card Details") {
                    TextField("Name", text: $card.name)
                }

                Section("Institution") {
                    Picker("Institution", selection: $card.institutionID) {
                        ForEach(viewModel.institutions) { institution in
                            Text(institution.name).tag(institution.id)
                        }
                    }
                }

                Section("Linked Account") {
                    Picker("Account", selection: $card.accountID) {
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
                            await viewModel.updateCard(card)
                        }
                    }
                }
            }
        }
        .alert("Convert to Account?", isPresented: $showConvertConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Convert", role: .destructive) {
                Task {
                    await viewModel.convertToAccount(card)
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
                }
            }
        } message: {
            Text("This will permanently delete this card and all associated transactions. This cannot be undone.")
        }
    }
}

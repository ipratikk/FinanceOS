import FinanceCore
import SwiftUI

struct CardEditView: View {
    let card: Card
    let viewModel: CardsViewModel
    @State private var name: String
    @State private var nickname: String
    @State private var last4: String
    @State private var institutionID: UUID
    @State private var accountID: UUID?
    @Environment(\.dismiss) var dismiss

    @State private var showDeleteConfirm = false
    @State private var showConvertConfirm = false

    init(card: Card, viewModel: CardsViewModel) {
        self.card = card
        self.viewModel = viewModel
        _name = State(initialValue: card.name)
        _nickname = State(initialValue: card.nickname)
        _last4 = State(initialValue: card.last4)
        _institutionID = State(initialValue: card.institutionID)
        _accountID = State(initialValue: card.accountID)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Card Details") {
                    TextField("Name", text: $name)
                    TextField("Nickname", text: $nickname)
                    TextField("Last 4 Digits", text: $last4)
                        .onChange(of: last4) { _, newValue in
                            if newValue.count > 4 {
                                last4 = String(newValue.prefix(4))
                            }
                        }
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
                            let updated = Card(
                                id: card.id,
                                institutionID: institutionID,
                                accountID: accountID,
                                name: name,
                                nickname: nickname,
                                last4: last4
                            )
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
                    await viewModel.convertToAccount(card)
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

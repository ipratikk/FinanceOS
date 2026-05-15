import FinanceCore
import SwiftUI

struct CardEditView: View {
    let card: Card
    let viewModel: CardsViewModel
    @State private var cardName: String
    @State private var cardLast4: String
    @State private var cardType: CardType
    @State private var nickname: String
    @State private var bankId: UUID
    @State private var linkedAccountId: UUID?
    @Environment(\.dismiss) var dismiss

    @State private var showDeleteConfirm = false
    @State private var showConvertConfirm = false

    init(card: Card, viewModel: CardsViewModel) {
        self.card = card
        self.viewModel = viewModel
        _cardName = State(initialValue: card.cardName)
        _cardLast4 = State(initialValue: card.cardLast4)
        _cardType = State(initialValue: card.cardType)
        _nickname = State(initialValue: card.nickname)
        _bankId = State(initialValue: card.bankId)
        _linkedAccountId = State(initialValue: card.linkedAccountId)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Card Details") {
                    TextField("Card Name", text: $cardName)
                    TextField("Last 4 Digits", text: $cardLast4)
                        .onChange(of: cardLast4) { _, newValue in
                            if newValue.count > 4 {
                                cardLast4 = String(newValue.prefix(4))
                            }
                        }
                    Picker("Card Type", selection: $cardType) {
                        ForEach(CardType.allCases, id: \.self) { type in
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

                Section("Linked Account") {
                    Picker("Account", selection: $linkedAccountId) {
                        Text("None").tag(UUID?.none)
                        ForEach(viewModel.accounts.filter { $0.bankId == bankId }) { account in
                            Text(account.accountName).tag(UUID?(account.id))
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
                                bankId: bankId,
                                linkedAccountId: linkedAccountId,
                                cardName: cardName,
                                cardLast4: cardLast4,
                                cardType: cardType,
                                nickname: nickname
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

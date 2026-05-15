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
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Edit Card")
                    .font(.system(size: 18, weight: .semibold))
                Spacer()
                Button(action: { dismiss() }, label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                })
            }
            .padding(AppSpacing.md)
            .background(AppColors.base)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Card Information")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.gray)

                        VStack(spacing: 8) {
                            inputField("Card Name", text: $cardName)
                            inputField("Last 4 Digits", text: $cardLast4)
                                .onChange(of: cardLast4) { _, newValue in
                                    if newValue.count > 4 {
                                        cardLast4 = String(newValue.prefix(4))
                                    }
                                }

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Card Type")
                                    .font(.system(size: 12, weight: .regular))
                                    .foregroundColor(.gray)
                                Picker("Type", selection: $cardType) {
                                    ForEach(CardType.allCases, id: \.self) { type in
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
                        Text("Bank & Account")
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
                            .padding(AppSpacing.xs)
                            .background(AppColors.surface2)
                            .cornerRadius(AppRadius.sm)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Linked Account")
                                    .font(.system(size: 12, weight: .regular))
                                    .foregroundColor(.gray)
                                Picker("Account", selection: $linkedAccountId) {
                                    Text("None").tag(UUID?.none)
                                    ForEach(viewModel.accounts.filter { $0.bankId == bankId }) { account in
                                        Text(account.accountName).tag(UUID?(account.id))
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
                                    .font(.system(size: 12))
                                Text("Delete Card")
                                    .font(.system(size: 14, weight: .medium))
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
                        .font(.system(size: 14, weight: .medium))
                        .frame(maxWidth: .infinity)
                })
                .foregroundColor(.gray)
                .padding(AppSpacing.sm)
                .background(AppColors.surface)
                .cornerRadius(AppRadius.md)

                Button(action: {
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
                        dismiss()
                    }
                }, label: {
                    Text("Save")
                        .font(.system(size: 14, weight: .semibold))
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

    private func inputField(_ label: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(.gray)
            TextField("", text: text)
                .font(.system(size: 13, weight: .regular))
                .padding(AppSpacing.xs)
                .background(AppColors.surface2)
                .cornerRadius(AppRadius.sm)
        }
    }
}

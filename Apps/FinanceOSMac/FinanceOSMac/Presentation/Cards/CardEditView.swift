import FinanceCore
import FinanceUI
import SwiftUI

struct CardEditView: View {
    let card: Ledger
    let viewModel: CardsViewModel
    @State private var displayName: String
    @State private var last4: String
    @State private var cardType: String
    @State private var nickname: String
    @State private var bankId: UUID
    @State private var linkedLedgerId: UUID?
    @Environment(\.dismiss) var dismiss

    @State private var showDeleteConfirm = false
    @State private var deleteErrorMessage: String?

    init(card: Ledger, viewModel: CardsViewModel) {
        self.card = card
        self.viewModel = viewModel
        _displayName = State(initialValue: card.displayName)
        _last4 = State(initialValue: card.last4)
        _cardType = State(initialValue: card.cardType ?? "other")
        _nickname = State(initialValue: card.nickname)
        _bankId = State(initialValue: card.bankId)
        _linkedLedgerId = State(initialValue: card.linkedLedgerId)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                FDSLabel("Edit Card", style: .headingMedium)
                Spacer()
                Button(action: { dismiss() }, label: {
                    Image(systemName: "xmark.circle.fill")
                        .headingSmall()
                        .foregroundColor(.gray)
                })
                .accessibilityLabel("Close")
            }
            .padding(AppSpacing.md)
            .background(AppColors.base)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        FDSLabel("Card Information", style: .subheading)

                        VStack(spacing: 8) {
                            inputField("Card Name", text: $displayName)
                            inputField("Last 4 Digits", text: $last4)
                                .onChange(of: last4) { _, newValue in
                                    if newValue.count > 4 {
                                        last4 = String(newValue.prefix(4))
                                    }
                                }

                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    FDSLabel("Card Network", style: .hint)
                                    Spacer()
                                    Button(action: { autoDetectCardType() }) {
                                        FDSLabel("Auto-detect", style: .caption, color: .secondary)
                                    }
                                    .disabled(last4.trimmingCharacters(in: .whitespaces).count < 4)
                                }
                                Picker("Network", selection: $cardType) {
                                    Text("Visa").tag("visa")
                                    Text("Mastercard").tag("mastercard")
                                    Text("American Express").tag("amex")
                                    Text("Discover").tag("discover")
                                    Text("Diners Club").tag("diners")
                                    Text("Other").tag("other")
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
                        FDSLabel("Bank & Account", style: .subheading)

                        VStack(spacing: 8) {
                            VStack(alignment: .leading, spacing: 4) {
                                FDSLabel("Bank", style: .hint)
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
                                FDSLabel("Linked Account", style: .hint)
                                Picker("Account", selection: $linkedLedgerId) {
                                    Text("None").tag(UUID?.none)
                                    ForEach(viewModel.accounts.filter { $0.bankId == bankId }) { account in
                                        Text(account.displayName).tag(UUID?(account.id))
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
                                    .labelSmall()
                                FDSLabel("Delete Card", style: .bodyLarge)
                                Spacer()
                            }
                            .foregroundColor(AppColors.debit)
                            .padding(AppSpacing.sm)
                            .frame(maxWidth: .infinity)
                            .background(AppColors.debit.opacity(0.1))
                            .cornerRadius(AppRadius.md)
                        })
                    }
                }
                .padding(AppSpacing.md)
            }

            Divider()

            HStack(spacing: 12) {
                Button(action: { dismiss() }, label: {
                    FDSLabel("Cancel", style: .bodyLarge)
                        .frame(maxWidth: .infinity)
                })
                .foregroundColor(.gray)
                .padding(AppSpacing.sm)
                .background(AppColors.surface)
                .cornerRadius(AppRadius.md)

                Button(action: {
                    Task {
                        let updated = Ledger(
                            id: card.id,
                            bankId: bankId,
                            kind: card.kind,
                            displayName: displayName,
                            last4: last4,
                            nickname: nickname,
                            ownerName: card.ownerName,
                            createdAt: card.createdAt,
                            accountType: card.accountType,
                            cardType: cardType,
                            cardProduct: card.cardProduct,
                            linkedLedgerId: linkedLedgerId,
                            isArchived: card.isArchived
                        )
                        await viewModel.updateCard(updated)
                        // Sheet dismisses via binding when editingCard is set to nil
                    }
                }, label: {
                    FDSLabel("Save", style: .monoAmount)
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
                    if viewModel.deleteError == nil {
                        dismiss()
                    } else {
                        deleteErrorMessage = viewModel.deleteError
                    }
                }
            }
        } message: {
            Text("This will permanently delete this card and all associated transactions. This cannot be undone.")
        }
        .alert("Delete Failed", isPresented: Binding(
            get: { deleteErrorMessage != nil },
            set: { if !$0 { deleteErrorMessage = nil } }
        )) {
            Button("OK") { deleteErrorMessage = nil }
        } message: {
            if let error = deleteErrorMessage {
                Text(error)
            }
        }
    }

    private func inputField(_ label: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            FDSLabel(label, style: .hint)
            FDSTextInput("", text: text, style: .bodyMedium)
                .padding(AppSpacing.xs)
                .background(AppColors.surface2)
                .cornerRadius(AppRadius.sm)
        }
    }

    private func autoDetectCardType() {
        cardType = BINParser.detectCardType(from: last4)
    }
}

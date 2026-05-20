import FinanceCore
import FinanceUI
import SwiftUI

struct CardEditView: View {
    let card: Ledger
    let context: CardEditContext
    @State private var nickname: String
    @State private var cardType: String
    @State private var last4: String
    @State private var cardProduct: String?
    @Environment(\.dismiss) var dismiss
    @State private var showDeleteConfirm = false

    init(card: Ledger, context: CardEditContext) {
        self.card = card
        self.context = context
        _nickname = State(initialValue: card.nickname)
        _cardType = State(initialValue: card.cardType ?? "credit")
        _last4 = State(initialValue: card.last4)
        _cardProduct = State(initialValue: card.cardProduct)
    }

    var body: some View {
        FDSSheet(
            title: "Edit Card",
            subtitle: card.displayName,
            onDismiss: { dismiss() }
        ) {
            VStack(alignment: .leading, spacing: 20) {
                FDSCard(cornerRadius: 12, padded: false) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("CARD DETAILS")
                            .font(.system(size: 10, weight: .semibold))
                            .tracking(0.2)
                            .foregroundColor(DesignTokens.Text.secondary)

                        fieldInput("Nickname", text: $nickname)
                        Divider().opacity(DesignTokens.Opacity.low)
                        fieldInput("Card Type", text: $cardType)
                        Divider().opacity(DesignTokens.Opacity.low)
                        fieldInput("Last 4 Digits", text: $last4)
                    }
                    .padding(12)
                }

                FDSCard(cornerRadius: 12, padded: false) {
                    VStack(alignment: .leading, spacing: 12) {
                        Button(action: { showDeleteConfirm = true }) {
                            HStack(spacing: 8) {
                                Image(systemName: "trash.fill")
                                    .font(.system(size: 12, weight: .semibold))
                                Text("Delete Card")
                                    .font(.system(size: 13, weight: .semibold))
                                Spacer()
                            }
                            .foregroundColor(Color(red: 1.0, green: 0.27, blue: 0.23))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(12)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .alert("Delete Card?", isPresented: $showDeleteConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                Task {
                    await context.deleteCard(id: card.id)
                    if context.deleteError == nil { dismiss() }
                }
            }
        } message: {
            Text("This will permanently delete this card and all associated transactions.")
        }
    }

    private func fieldInput(_ label: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label.uppercased())
                .font(.system(size: 10, weight: .semibold))
                .tracking(0.2)
                .foregroundColor(Color(red: 0.741, green: 0.761, blue: 0.800))
<<<<<<< HEAD
            TextField("", text: text)
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(Color(red: 0.945, green: 0.953, blue: 0.965))
=======
            FDSTextInput("", text: text, style: .labelSmall)
                .foregroundColor(DesignTokens.Text.primary)
>>>>>>> 50e856e (refactor: Replace hardcoded frames, corners, and shadows with design tokens)
                .padding(8)
                .background(DesignTokens.Background.inputWell)
                .cornerRadius(6)
        }
    }
}

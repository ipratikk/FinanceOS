import FinanceCore
import FinanceUI
import SwiftUI

enum CardEditMode {
    case edit(Ledger, CardEditContext)
    case createCard(prefill: TargetCreationState?, onCommit: (TargetCreationState) -> Void)
    case createAccount(prefill: TargetCreationState?, onCommit: (TargetCreationState) -> Void)
}

struct CardEditFormState: Equatable {
    var nickname = ""
    var cardType: CardNetwork = .other
    var first4 = ""
    var last4 = ""
    var customName = ""
    var cardholderName = ""
    var accountType = "savings"
    var selectedBank: Banks?
    var linkedLedgerId: UUID?
    var cardProductId = ""

    static func initial(for mode: CardEditMode) -> CardEditFormState {
        var state = CardEditFormState()
        switch mode {
        case let .edit(card, context):
            state.nickname = card.nickname
            state.cardType = card.cardType ?? .other
            state.last4 = card.last4
            state.customName = card.displayName
            state.cardholderName = card.ownerName
            state.accountType = card.accountType ?? "savings"
            state.cardProductId = card.cardProductId ?? ""
            state.linkedLedgerId = card.linkedLedgerId
            state.selectedBank = context.banks.first { $0.id == card.bankId }?.bank
        case let .createCard(prefill, _):
            if let prefillState = prefill {
                state.nickname = prefillState.nickname
                state.cardType = prefillState.cardType
                state.first4 = prefillState.first4
                state.last4 = prefillState.last4
                state.customName = prefillState.customName
                state.cardholderName = prefillState.cardholderName
                state.selectedBank = prefillState.selectedBank
                state.linkedLedgerId = prefillState.linkedLedgerId
                state.cardProductId = prefillState.cardProductId
            }
        case let .createAccount(prefill, _):
            if let prefillState = prefill {
                state.nickname = prefillState.nickname
                state.last4 = prefillState.last4
                state.customName = prefillState.customName
                state.cardholderName = prefillState.cardholderName
                state.accountType = prefillState.accountType
                state.selectedBank = prefillState.selectedBank
                state.linkedLedgerId = prefillState.linkedLedgerId
            }
        }
        return state
    }
}

struct CardEditView: View {
    let mode: CardEditMode
    @Environment(\.dismiss) var dismiss

    @State var form: CardEditFormState
    @State var showDeleteConfirm = false
    @State var showCardSelection = false

    init(mode: CardEditMode) {
        self.mode = mode
        _form = State(initialValue: CardEditFormState.initial(for: mode))
    }

    var isCard: Bool {
        switch mode {
        case let .edit(card, _): return card.kind == .creditCard
        case .createCard: return true
        case .createAccount: return false
        }
    }

    var isEdit: Bool {
        if case .edit = mode { return true }
        return false
    }

    var titleText: String {
        switch mode {
        case .edit: return isCard ? "Edit Card" : "Edit Account"
        case .createCard: return "Create Card"
        case .createAccount: return "Create Account"
        }
    }

    var selectedCatalogCard: CardMetadata? {
        guard !form.cardProductId.isEmpty else { return nil }
        return CardDatabase.supportedCards().first { $0.id == form.cardProductId }
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
            FDSTextInput("", text: text, style: .labelSmall)
                .foregroundColor(DesignTokens.Text.primary)
                .padding(8)
                .background(DesignTokens.Background.inputWell)
                .cornerRadius(6)
        }
        .frame(minWidth: 600, maxHeight: .infinity, alignment: .topLeading)
        .background(AppColors.base)
        .sheet(isPresented: $showDeleteConfirm) { deleteSheet }
        .sheet(isPresented: $showCardSelection) { cardSelectionSheet }
    }
}

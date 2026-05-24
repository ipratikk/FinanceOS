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
    @State var catalogMode = true

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
        case .createCard: return "Add New Card"
        case .createAccount: return "Add New Account"
        }
    }

    var subtitleText: String {
        switch mode {
        case .edit:
            return "Update your card details and configuration."
        case .createCard:
            return "Securely link your physical card to your digital wealth management dashboard. " +
                "Choose from our catalog or enter details manually."
        case .createAccount:
            return "Add a new bank account to track your finances."
        }
    }

    var selectedCatalogCard: CardMetadata? {
        guard !form.cardProductId.isEmpty else { return nil }
        return CardDatabase.supportedCards().first { $0.id == form.cardProductId }
    }

    private var screenFrame: CGRect {
        NSScreen.main?.visibleFrame ?? CGRect(x: 0, y: 0, width: 1440, height: 900)
    }

    private var sheetWidth: CGFloat {
        screenFrame.width * 0.4
    }

    private var sheetHeight: CGFloat {
        screenFrame.height * 0.7
    }

    private var cardPanelWidth: CGFloat {
        max(300, min(sheetWidth * 0.5, 420))
    }

    var body: some View {
        HStack(spacing: AppSpacing.xl) {
            if isCard {
                heroPanelSection
                    .frame(width: cardPanelWidth)
            }
            FDSCard(padded: true, glass: true, content: {
                VStack(spacing: AppSpacing.xl) {
                    headerBar
                    scrollContent
                    footerBar
                }
            })
            .padding(AppSpacing.xl)
        }
        .padding(AppSpacing.xxl)
        .background(AppColors.base)
        .frame(width: sheetWidth, height: sheetHeight)
        .onAppear { seedBankFromCatalogIfNeeded() }
        .onChange(of: contextBanksCount) { _, count in
            guard count > 0 else { return }
            seedBankFromEditContext()
        }
        .alert(
            "Delete \"\(isCard ? "Card" : "Account")\"?",
            isPresented: $showDeleteConfirm
        ) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                if case let .edit(card, context) = mode {
                    Task {
                        await context.deleteCard(id: card.id)
                        if context.deleteError == nil { dismiss() }
                    }
                }
            }
        } message: {
            FDSLabel("This will permanently delete this item and all associated transactions.")
        }
        .sheet(isPresented: $showCardSelection) {
            cardSelectionSheet
        }
    }

    private var contextBanksCount: Int {
        if case let .edit(_, context) = mode { return context.banks.count }
        return 0
    }

    private func seedBankFromCatalogIfNeeded() {
        guard form.selectedBank == nil, !form.cardProductId.isEmpty,
              let card = CardDatabase.supportedCards().first(where: { $0.id == form.cardProductId })
        else { return }
        form.selectedBank = Banks.allCases.first { bank in
            card.issuer.localizedCaseInsensitiveContains(bank.displayName) ||
                bank.displayName.localizedCaseInsensitiveContains(card.issuer)
        }
    }

    private func seedBankFromEditContext() {
        guard form.selectedBank == nil, case let .edit(card, context) = mode else { return }
        form.selectedBank = context.banks.first { $0.id == card.bankId }?.bank
    }
}

#Preview {
    CardEditView(mode: .createCard(prefill: nil, onCommit: { _ in }))
}

import FinanceCore
import FinanceUI
import SwiftUI

enum CardEditMode {
    case edit(Ledger)
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
        case let .edit(card):
            state.nickname = card.nickname
            state.cardType = card.cardType ?? .other
            state.last4 = card.last4
            state.customName = card.displayName
            state.cardholderName = card.ownerName
            state.accountType = card.accountType ?? "savings"
            state.cardProductId = card.cardProductId ?? ""
            state.linkedLedgerId = card.linkedLedgerId
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
    let banks: [Bank]
    @Environment(\.dismiss) var dismiss
    @State var viewModel: CardEditViewModel
    @State private var sizing = WindowSizing()

    init(
        mode: CardEditMode,
        ledgerRepository: (any LedgerRepository)? = nil,
        banks: [Bank] = [],
        accounts: [Ledger] = [],
        onUpdate: (() async -> Void)? = nil
    ) {
        self.banks = banks
        _viewModel = State(initialValue: CardEditViewModel(
            mode: mode,
            ledgerRepository: ledgerRepository,
            banks: banks,
            accounts: accounts,
            onUpdate: onUpdate
        ))
    }

    private var cardPanelWidth: CGFloat {
        max(
            300,
            min(sizing.clampedWidth(fraction: 0.7, min: 820, max: 1300) * 0.35, 420)
        )
    }

    var body: some View {
        HStack(spacing: AppSpacing.xl) {
            if viewModel.isCard {
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
        .responsiveFrame(
            widthFraction: 0.7,
            heightFraction: 0.7,
            minWidth: 900,
            maxWidth: 1300,
            minHeight: 700,
            maxHeight: 900
        )
        .onAppear { viewModel.seedBankFromCatalogIfNeeded() }
        .onChange(of: banks.count) { _, _ in viewModel.updateBanks(banks) }
        .onChange(of: viewModel.didCommit) { _, committed in if committed { dismiss() } }
        .alert(
            "Delete \"\(viewModel.isCard ? "Card" : "Account")\"?",
            isPresented: $viewModel.showDeleteConfirm
        ) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                Task { await viewModel.deleteCard() }
            }
        } message: {
            FDSLabel("This will permanently delete this item and all associated transactions.")
        }
        .sheet(isPresented: $viewModel.showCardSelection) {
            cardSelectionSheet
        }
    }
}

#Preview {
    CardEditView(mode: .createCard(prefill: nil, onCommit: { _ in }))
}

import FinanceCore
import FinanceUI
import SwiftUI

@Observable
@MainActor
final class CardEditViewModel {
    // MARK: - Dependencies

    private let ledgerRepository: (any LedgerRepository)?
    private let onUpdate: (() async -> Void)?

    // MARK: - Mode + Data

    let mode: CardEditMode
    var banks: [Bank]
    let accounts: [Ledger]

    // MARK: - Form State

    var form: CardEditFormState
    var showDeleteConfirm = false
    var showCardSelection = false
    var catalogMode = true
    var operationError: String?
    private(set) var didCommit = false

    // MARK: - Init

    init(
        mode: CardEditMode,
        ledgerRepository: (any LedgerRepository)? = nil,
        banks: [Bank] = [],
        accounts: [Ledger] = [],
        onUpdate: (() async -> Void)? = nil
    ) {
        self.mode = mode
        self.ledgerRepository = ledgerRepository
        self.banks = banks
        self.accounts = accounts
        self.onUpdate = onUpdate
        form = CardEditFormState.initial(for: mode)
    }

    // MARK: - Computed from Mode

    var isCard: Bool {
        switch mode {
        case let .edit(card): return card.kind == .creditCard
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

    // MARK: - Bank Updates

    func updateBanks(_ newBanks: [Bank]) {
        banks = newBanks
        seedBankFromEditContext()
    }

    // MARK: - Actions

    func commitEdit() async {
        guard case let .edit(card) = mode, let repo = ledgerRepository else { return }
        let newBankId = banks.first { $0.bank == form.selectedBank }?.id ?? card.bankId
        let updated = Ledger(
            id: card.id,
            bankId: newBankId,
            kind: card.kind,
            displayName: form.customName.isEmpty ? card.displayName : form.customName,
            last4: form.last4,
            nickname: form.nickname,
            ownerName: form.cardholderName,
            createdAt: card.createdAt,
            accountType: !isCard ? form.accountType : nil,
            cardType: isCard ? form.cardType : nil,
            cardProductId: form.cardProductId.isEmpty ? nil : form.cardProductId,
            bin: card.bin,
            linkedLedgerId: form.linkedLedgerId,
            isArchived: card.isArchived,
            closingBalance: card.closingBalance,
            closingBalanceAsOf: card.closingBalanceAsOf
        )
        do {
            try await repo.update(updated)
            operationError = nil
            await onUpdate?()
            didCommit = true
        } catch {
            operationError = error.localizedDescription
        }
    }

    func deleteCard() async {
        guard case let .edit(card) = mode, let repo = ledgerRepository else { return }
        do {
            try await repo.delete(id: card.id)
            operationError = nil
            didCommit = true
        } catch {
            operationError = error.localizedDescription
        }
    }

    func triggerCreate() {
        switch mode {
        case let .createCard(_, onCommit):
            onCommit(buildCreationState())
            didCommit = true
        case let .createAccount(_, onCommit):
            onCommit(buildCreationState())
            didCommit = true
        case .edit:
            break
        }
    }

    // MARK: - Private Helpers

    func buildCreationState() -> TargetCreationState {
        var state = TargetCreationState()
        state.customName = form.customName
        state.nickname = form.nickname
        state.first4 = form.first4
        state.last4 = form.last4
        state.cardholderName = form.cardholderName
        state.selectedBank = form.selectedBank
        state.isCard = isCard
        state.accountType = form.accountType
        state.cardType = form.cardType
        state.cardProductId = form.cardProductId
        state.linkedLedgerId = form.linkedLedgerId
        return state
    }

    func seedBankFromCatalogIfNeeded() {
        guard form.selectedBank == nil, !form.cardProductId.isEmpty,
              let card = CardDatabase.supportedCards().first(where: { $0.id == form.cardProductId })
        else { return }
        form.selectedBank = Banks.allCases.first { bank in
            card.issuer.localizedCaseInsensitiveContains(bank.displayName) ||
                bank.displayName.localizedCaseInsensitiveContains(card.issuer)
        }
    }

    func seedBankFromEditContext() {
        guard form.selectedBank == nil, case let .edit(card) = mode else { return }
        form.selectedBank = banks.first { $0.id == card.bankId }?.bank
    }
}

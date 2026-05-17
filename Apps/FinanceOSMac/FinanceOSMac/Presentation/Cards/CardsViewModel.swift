//
//  CardsViewModel.swift
//  FinanceOSMac
//
//  Created by Pratik Goel on 13/05/26.
//

import FinanceCore
import Foundation
import Observation
import OSLog

@Observable
final class CardsViewModel {
    struct CardRow: Identifiable {
        let id: UUID
        let card: Ledger
        let title: String
        let institutionName: String
        let linkedAccountName: String?

        var subtitle: String {
            if let linkedAccountName {
                return "\(institutionName) · \(linkedAccountName)"
            }

            return institutionName
        }
    }

    private let ledgerRepository: LedgerRepository
    private let bankRepository: BankRepository
    private let transactionRepository: TransactionRepository
    private let logger = FinanceLogger.ui

    var cardRows: [CardRow] = []
    var isLoading = false
    var editingCard: Ledger?
    var banks: [Bank] = []
    var accounts: [Ledger] = []
    var deleteError: String?

    init(
        ledgerRepository: LedgerRepository,
        bankRepository: BankRepository,
        transactionRepository: TransactionRepository
    ) {
        self.ledgerRepository = ledgerRepository
        self.bankRepository = bankRepository
        self.transactionRepository = transactionRepository
    }

    func loadCards() async {
        isLoading = true

        defer {
            isLoading = false
        }

        do {
            let cards = try await ledgerRepository
                .fetchLedgers(kind: .creditCard)
            let accounts = try await ledgerRepository
                .fetchLedgers(kind: .bankAccount)
            let banks = try await bankRepository
                .fetchBanks()

            self.accounts = accounts
            self.banks = banks

            cardRows = makeCardRows(
                cards: cards,
                accounts: accounts,
                banks: banks
            )

        } catch {
            logger.logError(
                "Failed to load cards: {error}",
                ["error": error.localizedDescription]
            )
        }
    }

    func updateCard(_ card: Ledger) async {
        do {
            try await ledgerRepository.update(card)
            await loadCards()
            editingCard = nil
        } catch {
            logger.logError(
                "Failed to update card: {error}",
                ["cardId": card.id.uuidString, "error": error.localizedDescription]
            )
        }
    }

    func deleteCard(id: UUID) async {
        do {
            deleteError = nil
            logger.logDebug(
                "Deleting card",
                ["cardId": id.uuidString]
            )
            try await ledgerRepository.delete(id: id)
            logger.logInfo(
                "Card deleted successfully",
                ["cardId": id.uuidString]
            )
            await loadCards()
        } catch {
            logger.logError(
                "Delete card failed: {error}",
                ["cardId": id.uuidString, "error": error.localizedDescription]
            )
            deleteError = error.localizedDescription
        }
    }

    func convertToAccount(_ card: Ledger) async {
        do {
            let account = Ledger(
                id: UUID(),
                bankId: card.bankId,
                kind: .bankAccount,
                displayName: card.displayName,
                last4: card.last4
            )
            try await ledgerRepository.insert(account)
            try await transactionRepository.migrateTransactions(fromCard: card.id, toAccount: account.id)
            try await ledgerRepository.delete(id: card.id)
            await loadCards()
            editingCard = nil
        } catch {
            logger.logError(
                "Failed to convert card to account: {error}",
                ["cardId": card.id.uuidString, "error": error.localizedDescription]
            )
        }
    }

    private func makeCardRows(
        cards: [Ledger],
        accounts: [Ledger],
        banks: [Bank]
    ) -> [CardRow] {
        let accountsByID = Dictionary(
            uniqueKeysWithValues: accounts.map { account in
                (account.id, account)
            }
        )

        let banksByID = Dictionary(
            uniqueKeysWithValues: banks.map { bank in
                (bank.id, bank)
            }
        )

        return cards.map { card in
            let bankName = banksByID[card.bankId]?.name ?? "Unknown Bank"
            let displayName = card.nickname.isEmpty ? card.displayName : card.nickname
            let maskLast4 = card.last4.isEmpty ? "" : " ••••\(card.last4)"
            let title = "\(bankName) \(displayName)\(maskLast4)".trimmingCharacters(in: .whitespaces)

            return CardRow(
                id: card.id,
                card: card,
                title: title,
                institutionName: bankName,
                linkedAccountName: card.linkedLedgerId.flatMap { accountID in
                    accountsByID[accountID]?.displayName
                }
            )
        }
    }
}

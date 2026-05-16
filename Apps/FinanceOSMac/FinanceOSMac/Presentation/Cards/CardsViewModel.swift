//
//  CardsViewModel.swift
//  FinanceOSMac
//
//  Created by Pratik Goel on 13/05/26.
//

import FinanceCore
import Foundation
import Observation

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

    var cardRows: [CardRow] = []
    var isLoading = false
    var editingCard: Ledger?
    var banks: [Bank] = []
    var accounts: [Ledger] = []

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
            print(error)
        }
    }

    func updateCard(_ card: Ledger) async {
        do {
            try await ledgerRepository.update(card)
            await loadCards()
            editingCard = nil
        } catch {
            print(error)
        }
    }

    func deleteCard(id: UUID) async {
        do {
            try await ledgerRepository.delete(id: id)
            await loadCards()
        } catch {
            print(error)
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
            print(error)
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
            let title = "\(bankName) \(displayName)\(maskLast4)"

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

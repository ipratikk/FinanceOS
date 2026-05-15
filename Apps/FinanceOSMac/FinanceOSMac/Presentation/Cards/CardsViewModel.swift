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
        let card: Card
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

    private let cardRepository: CardRepository
    private let accountRepository: AccountRepository
    private let bankRepository: BankRepository
    private let transactionRepository: TransactionRepository

    var cardRows: [CardRow] = []
    var isLoading = false
    var editingCard: Card?
    var banks: [Bank] = []
    var accounts: [Account] = []

    init(
        cardRepository: CardRepository,
        accountRepository: AccountRepository,
        bankRepository: BankRepository,
        transactionRepository: TransactionRepository
    ) {
        self.cardRepository = cardRepository
        self.accountRepository = accountRepository
        self.bankRepository = bankRepository
        self.transactionRepository = transactionRepository
    }

    func loadCards() async {
        isLoading = true

        defer {
            isLoading = false
        }

        do {
            let cards = try await cardRepository
                .fetchCards()
            let accounts = try await accountRepository
                .fetchAccounts()
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

    func updateCard(_ card: Card) async {
        do {
            try await cardRepository.update(card)
            await loadCards()
            editingCard = nil
        } catch {
            print(error)
        }
    }

    func deleteCard(id: UUID) async {
        do {
            try await cardRepository.delete(id: id)
            await loadCards()
        } catch {
            print(error)
        }
    }

    func convertToAccount(_ card: Card) async {
        do {
            let account = Account(
                bankId: card.bankId,
                accountName: card.cardName
            )
            try await accountRepository.insert(account)
            try await transactionRepository.migrateTransactions(fromCard: card.id, toAccount: account.id)
            try await cardRepository.delete(id: card.id)
            await loadCards()
            editingCard = nil
        } catch {
            print(error)
        }
    }

    private func makeCardRows(
        cards: [Card],
        accounts: [Account],
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
            let displayName = card.nickname.isEmpty ? card.cardName : card.nickname
            let maskLast4 = card.cardLast4.isEmpty ? "" : " ••••\(card.cardLast4)"
            let title = "\(bankName) \(displayName)\(maskLast4)"

            return CardRow(
                id: card.id,
                card: card,
                title: title,
                institutionName: bankName,
                linkedAccountName: card.linkedAccountId.flatMap { accountID in
                    accountsByID[accountID]?.accountName
                }
            )
        }
    }
}

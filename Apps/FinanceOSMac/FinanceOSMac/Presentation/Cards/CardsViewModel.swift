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
    private let institutionRepository: InstitutionRepository
    private let transactionRepository: TransactionRepository

    var cardRows: [CardRow] = []
    var isLoading = false
    var editingCard: Card?
    var institutions: [Institution] = []
    var accounts: [Account] = []

    init(
        cardRepository: CardRepository,
        accountRepository: AccountRepository,
        institutionRepository: InstitutionRepository,
        transactionRepository: TransactionRepository
    ) {
        self.cardRepository = cardRepository
        self.accountRepository = accountRepository
        self.institutionRepository = institutionRepository
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
            let institutions = try await institutionRepository
                .fetchInstitutions()

            self.accounts = accounts
            self.institutions = institutions

            cardRows = makeCardRows(
                cards: cards,
                accounts: accounts,
                institutions: institutions
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
                institutionID: card.institutionID,
                name: card.name
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
        institutions: [Institution]
    ) -> [CardRow] {
        let accountsByID = Dictionary(
            uniqueKeysWithValues: accounts.map { account in
                (account.id, account)
            }
        )

        let institutionsByID = Dictionary(
            uniqueKeysWithValues: institutions.map { institution in
                (institution.id, institution)
            }
        )

        return cards.map { card in
            CardRow(
                id: card.id,
                card: card,
                title: card.name,
                institutionName: institutionsByID[card.institutionID]?.name ?? "Unknown Institution",
                linkedAccountName: card.accountID.flatMap { accountID in
                    accountsByID[accountID]?.name
                }
            )
        }
    }
}

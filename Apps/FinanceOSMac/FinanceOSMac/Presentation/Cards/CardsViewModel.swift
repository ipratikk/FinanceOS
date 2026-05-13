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

    var cardRows: [CardRow] = []

    var isLoading = false

    init(
        cardRepository: CardRepository,
        accountRepository: AccountRepository,
        institutionRepository: InstitutionRepository
    ) {
        self.cardRepository = cardRepository
        self.accountRepository = accountRepository
        self.institutionRepository = institutionRepository
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

            cardRows = makeCardRows(
                cards: cards,
                accounts: accounts,
                institutions: institutions
            )

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
                title: card.name,
                institutionName: institutionsByID[card.institutionID]?.name ?? "Unknown Institution",
                linkedAccountName: card.accountID.flatMap { accountID in
                    accountsByID[accountID]?.name
                }
            )
        }
    }
}

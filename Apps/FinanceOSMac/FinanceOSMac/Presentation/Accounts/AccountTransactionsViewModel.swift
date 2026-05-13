//
//  AccountTransactionsViewModel.swift
//  FinanceOSMac
//
//  Created by Pratik Goel on 13/05/26.
//

import FinanceCore
import Foundation
import Observation

@Observable
final class AccountTransactionsViewModel {
    struct TransactionRow: Identifiable {
        let id: UUID
        let title: String
        let subtitle: String
        let amountText: String
        let transactionType: TransactionType
    }

    private let transactionRepository: TransactionRepository
    private let cardRepository: CardRepository

    var transactionRows: [TransactionRow] = []

    var isLoading = false

    init(
        transactionRepository: TransactionRepository,
        cardRepository: CardRepository
    ) {
        self.transactionRepository = transactionRepository
        self.cardRepository = cardRepository
    }

    func loadTransactions(for accountID: UUID) async {
        isLoading = true

        defer {
            isLoading = false
        }

        do {
            let transactions = try await transactionRepository
                .fetchTransactionsForAccount(accountID)
            let cards = try await cardRepository
                .fetchCards()

            transactionRows = makeTransactionRows(
                transactions: transactions,
                cards: cards
            )

        } catch {
            print(error)
        }
    }

    private func makeTransactionRows(
        transactions: [Transaction],
        cards: [Card]
    ) -> [TransactionRow] {
        let cardsByID = Dictionary(
            uniqueKeysWithValues: cards.map { card in
                (card.id, card)
            }
        )

        return transactions.map { transaction in
            let sourceName: String = (
                transaction.cardID.flatMap { cardsByID[$0] }?.name ??
                    "Unknown Source"
            )

            return TransactionRow(
                id: transaction.id,
                title: transaction.description,
                subtitle: sourceName,
                amountText: amountText(
                    minorUnits: transaction.amountMinorUnits,
                    currencyCode: transaction.currencyCode,
                    transactionType: transaction.transactionType
                ),
                transactionType: transaction.transactionType
            )
        }
    }

    private func amountText(
        minorUnits: Int64,
        currencyCode: String,
        transactionType: TransactionType
    ) -> String {
        let wholeUnits = minorUnits / 100
        let fractionalUnits = minorUnits % 100
        let sign = transactionType == .debit ? "-" : "+"

        return "\(sign)\(currencyCode) \(wholeUnits).\(String(format: "%02d", fractionalUnits))"
    }
}

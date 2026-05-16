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
    private let transactionRepository: TransactionRepository
    private let ledgerRepository: LedgerRepository

    var transactionRows: [TransactionRow] = []
    var listState = TransactionListState()

    var isLoading = false

    var sections: [TransactionSection] {
        listState.sections(from: transactionRows)
    }

    init(
        transactionRepository: TransactionRepository,
        ledgerRepository: LedgerRepository
    ) {
        self.transactionRepository = transactionRepository
        self.ledgerRepository = ledgerRepository
    }

    func loadTransactions(for accountID: UUID) async {
        isLoading = true

        defer {
            isLoading = false
        }

        do {
            let transactions = try await transactionRepository
                .fetchTransactionsForAccount(accountID)
            let cards = try await ledgerRepository
                .fetchLedgers(kind: .creditCard)

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
        cards: [Ledger]
    ) -> [TransactionRow] {
        let cardsByID = Dictionary(
            uniqueKeysWithValues: cards.map { card in
                (card.id, card)
            }
        )

        return transactions.map { transaction in
            let sourceName: String = (
                transaction.cardID.flatMap { cardsByID[$0] }?.displayName ??
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
                transactionType: transaction.transactionType,
                postedAt: transaction.postedAt
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

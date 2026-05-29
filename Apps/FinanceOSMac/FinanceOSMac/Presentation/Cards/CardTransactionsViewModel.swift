//
//  CardTransactionsViewModel.swift
//  FinanceOSMac
//
//  Created by Pratik Goel on 13/05/26.
//

import FinanceCore
import Foundation
import Observation

@MainActor
@Observable
final class CardTransactionsViewModel: AsyncLoadable, DeletableViewModel {
    private let transactionRepository: TransactionRepository

    var transactionRows: [TransactionRow] = []
    var listState = TransactionListState()

    var isLoading = false
    var deleteError: String?

    var sections: [TransactionSection] {
        listState.sections(from: transactionRows)
    }

    init(
        transactionRepository: TransactionRepository
    ) {
        self.transactionRepository = transactionRepository
    }

    func loadTransactions(for cardID: UUID) async {
        await withLoading(onError: { error in
            FinanceLogger.userInterface.logError(
                "Failed to load transactions for {cardID}",
                caughtError: error,
                ["cardID": cardID.uuidString]
            )
        }, {
            let transactions = try await transactionRepository.fetchTransactionsForCard(cardID)
            transactionRows = makeTransactionRows(transactions: transactions)
            listState.updateAvailableYears(from: transactionRows)
        })
    }

    private func makeTransactionRows(
        transactions: [Transaction]
    ) -> [TransactionRow] {
        transactions.map { transaction in
            TransactionRow(
                id: transaction.id,
                title: transaction.description,
                subtitle: "",
                amountText: transaction.amountMinorUnits.formattedAsAmount(
                    currencyCode: transaction.currencyCode,
                    transactionType: transaction.transactionType
                ),
                transactionType: transaction.transactionType,
                postedAt: transaction.postedAt
            )
        }
    }

    func deleteTransaction(id: UUID, cardID: UUID) async {
        await performDelete {
            try await transactionRepository.delete(id: id)
        } onSuccess: { [self] in
            await loadTransactions(for: cardID)
        }
    }
}

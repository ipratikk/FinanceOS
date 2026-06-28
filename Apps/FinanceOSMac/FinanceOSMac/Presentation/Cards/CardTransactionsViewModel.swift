//
//  CardTransactionsViewModel.swift
//  FinanceOSMac
//
//  Created by Pratik Goel on 13/05/26.
//

import FinanceCore
import FinanceOSAPI
import Foundation
import Observation

@MainActor
@Observable
final class CardTransactionsViewModel: AsyncLoadable, DeletableViewModel {
    private let graphQLClient: ApolloGraphQLClient

    var transactionRows: [TransactionRow] = []
    var listState = TransactionListState()

    var isLoading = false
    var deleteError: String?

    var sections: [TransactionSection] {
        listState.sections(from: transactionRows)
    }

    init(graphQLClient: ApolloGraphQLClient) {
        self.graphQLClient = graphQLClient
    }

    func loadTransactions(for cardID: UUID) async {
        await withLoading(onError: { error in
            FinanceLogger.userInterface.logError(
                "Failed to load transactions for {cardID}",
                caughtError: error,
                ["cardID": cardID.uuidString]
            )
        }, {
            let data = try await graphQLClient.fetch(
                query: GetTransactionsQuery(
                    ledgerId: .some(cardID.uuidString),
                    filter: .none,
                    limit: .none
                )
            )
            let transactions = data.transactions.map(GraphQLMappings.mapTransaction)
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
                postedAt: transaction.postedAt,
                merchantName: transaction.merchantName,
                enrichedDescription: transaction.enrichedDescription
            )
        }
    }

    func deleteTransaction(id: UUID, cardID: UUID) async {
        await performDelete {
            _ = try await graphQLClient.perform(mutation: DeleteTransactionMutation(id: id.uuidString))
        } onSuccess: { [self] in
            await loadTransactions(for: cardID)
        }
    }
}

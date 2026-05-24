//
//  CardTransactionsViewModel.swift
//  FinanceOSMac
//
//  Created by Pratik Goel on 13/05/26.
//

import FinanceCore
import Foundation
import Observation

@Observable
final class CardTransactionsViewModel {
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
        isLoading = true

        defer {
            isLoading = false
        }

        do {
            let transactions = try await transactionRepository
                .fetchTransactionsForCard(cardID)

            transactionRows = makeTransactionRows(
                transactions: transactions
            )
            listState.updateAvailableYears(from: transactionRows)

        } catch {
            FinanceLogger.userInterface.logError(
                "Failed to load transactions for {cardID}",
                caughtError: error,
                ["cardID": cardID.uuidString]
            )
        }
    }

    private func makeTransactionRows(
        transactions: [Transaction]
    ) -> [TransactionRow] {
        transactions.map { transaction in
            TransactionRow(
                id: transaction.id,
                title: transaction.description,
                subtitle: "",
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

    func deleteTransaction(id: UUID, cardID: UUID) async {
        do {
            deleteError = nil
            try await transactionRepository.delete(id: id)
            await loadTransactions(for: cardID)
        } catch {
            deleteError = error.localizedDescription
        }
    }

    private func amountText(
        minorUnits: Int64,
        currencyCode: String,
        transactionType: TransactionType
    ) -> String {
        let whole = minorUnits / 100
        let frac = minorUnits % 100
        let sign = transactionType == .debit ? "-" : "+"
        let symbol = CurrencySymbol.symbol(for: currencyCode)
        return "\(sign)\(symbol)\(whole).\(String(format: "%02d", frac))"
    }
}

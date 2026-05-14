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
    private let accountRepository: AccountRepository

    var transactionRows: [TransactionRow] = []
    var listState = TransactionListState()

    var isLoading = false

    var sections: [TransactionSection] {
        listState.sections(from: transactionRows)
    }

    init(
        transactionRepository: TransactionRepository,
        accountRepository: AccountRepository
    ) {
        self.transactionRepository = transactionRepository
        self.accountRepository = accountRepository
    }

    func loadTransactions(for cardID: UUID) async {
        isLoading = true

        defer {
            isLoading = false
        }

        do {
            let transactions = try await transactionRepository
                .fetchTransactionsForCard(cardID)
            let accounts = try await accountRepository
                .fetchAccounts()

            transactionRows = makeTransactionRows(
                transactions: transactions,
                accounts: accounts
            )

        } catch {
            print(error)
        }
    }

    private func makeTransactionRows(
        transactions: [Transaction],
        accounts: [Account]
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

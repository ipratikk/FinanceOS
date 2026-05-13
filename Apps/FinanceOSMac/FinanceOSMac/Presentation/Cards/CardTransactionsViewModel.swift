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
    struct TransactionRow: Identifiable {
        let id: UUID
        let title: String
        let subtitle: String
        let amountText: String
        let transactionType: TransactionType
    }

    private let transactionRepository: TransactionRepository
    private let accountRepository: AccountRepository

    var transactionRows: [TransactionRow] = []

    var isLoading = false

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
        let accountsByID = Dictionary(
            uniqueKeysWithValues: accounts.map { account in
                (account.id, account)
            }
        )

        return transactions.map { transaction in
            let sourceName: String = if let accountID = transaction.accountID,
                                        let account = accountsByID[accountID]
            {
                account.name
            } else {
                "Unknown Source"
            }

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

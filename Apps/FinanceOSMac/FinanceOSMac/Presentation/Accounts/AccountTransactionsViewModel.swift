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
    var deleteError: String?

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
            let ledgers = try await ledgerRepository
                .fetchLedgers()

            transactionRows = makeTransactionRows(
                transactions: transactions,
                ledgers: ledgers
            )

        } catch {
            print(error)
        }
    }

    private func makeTransactionRows(
        transactions: [Transaction],
        ledgers: [Ledger]
    ) -> [TransactionRow] {
        let ledgersByID = Dictionary(
            uniqueKeysWithValues: ledgers.map { ledger in
                (ledger.id, ledger)
            }
        )

        return transactions.map { transaction in
            let ledger = transaction.ledgerId.flatMap { ledgersByID[$0] }
            let sourceName: String = ledger?.displayName ?? "Unknown Source"

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

    func deleteTransaction(id: UUID, accountID: UUID) async {
        do {
            deleteError = nil
            try await transactionRepository.delete(id: id)
            await loadTransactions(for: accountID)
        } catch {
            deleteError = error.localizedDescription
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

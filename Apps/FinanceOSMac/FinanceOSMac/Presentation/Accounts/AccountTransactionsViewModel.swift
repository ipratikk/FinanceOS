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
    private let bankRepository: any BankRepository

    var transactionRows: [TransactionRow] = []
    var listState = TransactionListState()
    var bank: Bank?

    var isLoading = false
    var deleteError: String?

    var sections: [TransactionSection] {
        listState.sections(from: transactionRows)
    }

    init(
        transactionRepository: TransactionRepository,
        ledgerRepository: LedgerRepository,
        bankRepository: any BankRepository
    ) {
        self.transactionRepository = transactionRepository
        self.ledgerRepository = ledgerRepository
        self.bankRepository = bankRepository
    }

    func loadTransactions(for accountID: UUID, bankId: UUID, closingBalance: Int64?) async {
        isLoading = true

        defer {
            isLoading = false
        }

        do {
            async let txnsFetch = transactionRepository.fetchTransactionsForAccount(accountID)
            async let ledgersFetch = ledgerRepository.fetchLedgers()
            async let banksFetch = bankRepository.fetchBanks()

            let (transactions, ledgers, banks) = try await (txnsFetch, ledgersFetch, banksFetch)
            bank = banks.first { $0.id == bankId }

            transactionRows = makeTransactionRows(
                transactions: transactions,
                ledgers: ledgers,
                closingBalance: closingBalance
            )
            listState.updateAvailableYears(from: transactionRows)

        } catch {
            FinanceLogger.ui.logError(
                "Failed to load account transactions for {accountID}",
                caughtError: error,
                ["accountID": accountID.uuidString]
            )
        }
    }

    private func makeTransactionRows(
        transactions: [Transaction],
        ledgers: [Ledger],
        closingBalance: Int64?
    ) -> [TransactionRow] {
        let ledgersByID = Dictionary(
            uniqueKeysWithValues: ledgers.map { ledger in (ledger.id, ledger) }
        )

        let sorted = transactions.sorted { $0.postedAt > $1.postedAt }
        var runningBalances: [UUID: String] = [:]

        if let closingBalance {
            let currencyCode = sorted.first?.currencyCode ?? "INR"
            var balance = closingBalance
            for txn in sorted {
                runningBalances[txn.id] = balanceText(minorUnits: balance, currencyCode: currencyCode)
                balance += txn.transactionType == .debit ? txn.amountMinorUnits : -txn.amountMinorUnits
            }
        }

        return sorted.map { transaction in
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
                postedAt: transaction.postedAt,
                runningBalance: runningBalances[transaction.id]
            )
        }
    }

    func deleteTransaction(id: UUID, accountID: UUID, bankId: UUID, closingBalance: Int64?) async {
        do {
            deleteError = nil
            try await transactionRepository.delete(id: id)
            await loadTransactions(for: accountID, bankId: bankId, closingBalance: closingBalance)
        } catch {
            deleteError = error.localizedDescription
        }
    }

    private func balanceText(minorUnits: Int64, currencyCode: String) -> String {
        let whole = minorUnits / 100
        let frac = abs(minorUnits % 100)
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        formatter.groupingSize = 3
        let formatted = formatter.string(from: NSNumber(value: whole)) ?? "\(whole)"
        let symbol = CurrencySymbol.symbol(for: currencyCode)
        return "\(symbol)\(formatted).\(String(format: "%02d", frac))"
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

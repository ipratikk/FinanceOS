//
//  AccountTransactionsViewModel.swift
//  FinanceOSMac
//
//  Created by Pratik Goel on 13/05/26.
//

import FinanceCore
import FinanceUI
import Foundation
import Observation

@MainActor
@Observable
final class AccountTransactionsViewModel: AsyncLoadable, DeletableViewModel {
    private let transactionRepository: TransactionRepository
    private let ledgerRepository: LedgerRepository
    private let bankRepository: any BankRepository
    private let balanceService: any AccountBalanceProtocol

    var transactionRows: [TransactionRow] = []
    var listState = TransactionListState()
    var bank: Bank?

    var isLoading = false
    var deleteError: String?

    var sections: [TransactionSection] {
        listState.sections(from: transactionRows)
    }

    func closingBalanceText(for ledger: Ledger) -> String? {
        guard let balance = ledger.closingBalance else { return nil }
        return MoneyFormatting.formatRunningBalance(minorUnits: balance)
    }

    func closingDateText(for ledger: Ledger) -> String? {
        guard let date = ledger.closingBalanceAsOf else { return nil }
        return FormatterCache.dayMonthYear.string(from: date)
    }

    init(
        transactionRepository: TransactionRepository,
        ledgerRepository: LedgerRepository,
        bankRepository: any BankRepository,
        balanceService: (any AccountBalanceProtocol)? = nil
    ) {
        self.transactionRepository = transactionRepository
        self.ledgerRepository = ledgerRepository
        self.bankRepository = bankRepository
        self.balanceService = balanceService ?? AccountBalanceService()
    }

    func loadTransactions(for accountID: UUID, bankId: UUID, closingBalance: Int64?) async {
        await withLoading(onError: { error in
            FinanceLogger.userInterface.logError(
                "Failed to load account transactions for {accountID}",
                caughtError: error,
                ["accountID": accountID.uuidString]
            )
        }, {
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
        })
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
            runningBalances = balanceService.computeRunningBalances(
                sortedTransactions: sorted,
                closingBalance: closingBalance,
                currencyCode: currencyCode
            )
        }

        return sorted.map { transaction in
            let ledger = transaction.ledgerId.flatMap { ledgersByID[$0] }
            let sourceName: String = ledger?.displayName ?? "Unknown Source"

            return TransactionRow(
                id: transaction.id,
                title: transaction.description,
                subtitle: sourceName,
                amountText: transaction.amountMinorUnits.formattedAsAmount(
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
        await performDelete {
            try await transactionRepository.delete(id: id)
        } onSuccess: { [self] in
            await loadTransactions(for: accountID, bankId: bankId, closingBalance: closingBalance)
        }
    }
}

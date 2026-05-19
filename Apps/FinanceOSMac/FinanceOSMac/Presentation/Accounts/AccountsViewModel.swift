//
//  AccountsViewModel.swift
//  FinanceOSMac
//
//  Created by Pratik Goel on 13/05/26.
//

import FinanceCore
import Foundation
import Observation
import OSLog

@Observable
final class AccountsViewModel {
    private let ledgerRepository: LedgerRepository
    private let bankRepository: BankRepository
    private let transactionRepository: TransactionRepository
    private let logger = FinanceLogger.ui

    struct AccountLedgerBalance {
        let netMinorUnits: Int64
        let latestPostedAt: Date?

        var formattedBalance: String {
            let absValue = abs(netMinorUnits)
            let rupees = absValue / 100
            let paise = absValue % 100
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            formatter.locale = Locale(identifier: "en_IN")
            let formatted = formatter.string(from: NSNumber(value: rupees)) ?? "\(rupees)"
            let sign = netMinorUnits < 0 ? "-" : ""
            return paise > 0 ? "\(sign)₹\(formatted).\(String(format: "%02d", paise))" : "\(sign)₹\(formatted)"
        }

        var formattedDate: String? {
            guard let date = latestPostedAt else { return nil }
            let df = DateFormatter()
            df.dateFormat = "dd/MM/yyyy"
            return df.string(from: date)
        }
    }

    var accounts: [Ledger] = []
    var banks: [Bank] = []
    var balancesByAccount: [UUID: AccountLedgerBalance] = [:]
    var isLoading = false
    var deleteError: String?

    init(
        ledgerRepository: LedgerRepository,
        bankRepository: BankRepository,
        transactionRepository: TransactionRepository
    ) {
        self.ledgerRepository = ledgerRepository
        self.bankRepository = bankRepository
        self.transactionRepository = transactionRepository
    }

    func loadAccounts() async {
        isLoading = true

        defer {
            isLoading = false
        }

        do {
            async let accounts = ledgerRepository.fetchLedgers(kind: .bankAccount)
            async let banks = bankRepository.fetchBanks()
            self.accounts = try await accounts
            self.banks = try await banks
            await loadBalances(for: self.accounts)
        } catch {
            logger.logError(
                "Failed to load accounts: {error}",
                ["error": error.localizedDescription]
            )
        }
    }

    private func loadBalances(for accounts: [Ledger]) async {
        var result: [UUID: AccountLedgerBalance] = [:]
        for account in accounts {
            guard let txns = try? await transactionRepository.fetchTransactionsForAccount(account.id),
                  !txns.isEmpty else { continue }
            // closingBalanceAsOf is the statement date of the most recent imported statement
            let balanceDate = account.closingBalanceAsOf ?? txns.map(\.postedAt).max()
            let balanceMinorUnits: Int64 = if let closing = account.closingBalance {
                closing
            } else {
                txns.reduce(into: Int64(0)) { acc, txn in
                    acc += txn.transactionType == .credit ? txn.amountMinorUnits : -txn.amountMinorUnits
                }
            }
            result[account.id] = AccountLedgerBalance(netMinorUnits: balanceMinorUnits, latestPostedAt: balanceDate)
        }
        balancesByAccount = result
    }

    func updateAccount(_ account: Ledger) async {
        do {
            try await ledgerRepository.update(account)
            await loadAccounts()
        } catch {
            logger.logError(
                "Failed to update account: {error}",
                ["accountId": account.id.uuidString, "error": error.localizedDescription]
            )
        }
    }

    func deleteAccount(id: UUID) async {
        do {
            deleteError = nil
            logger.logDebug(
                "Deleting account",
                ["accountId": id.uuidString]
            )
            try await ledgerRepository.delete(id: id)
            logger.logInfo(
                "Account deleted successfully",
                ["accountId": id.uuidString]
            )
            await loadAccounts()
        } catch {
            logger.logError(
                "Delete account failed: {error}",
                ["accountId": id.uuidString, "error": error.localizedDescription]
            )
            deleteError = error.localizedDescription
        }
    }

    func convertToCard(_ account: Ledger) async {
        do {
            let card = Ledger(
                id: UUID(),
                bankId: account.bankId,
                kind: .creditCard,
                displayName: account.displayName,
                last4: account.last4,
                linkedLedgerId: account.id
            )
            try await ledgerRepository.insert(card)
            try await transactionRepository.migrateTransactions(fromAccount: account.id, toCard: card.id)
            try await ledgerRepository.delete(id: account.id)
            await loadAccounts()
        } catch {
            logger.logError(
                "Failed to convert account to card: {error}",
                ["accountId": account.id.uuidString, "error": error.localizedDescription]
            )
        }
    }
}

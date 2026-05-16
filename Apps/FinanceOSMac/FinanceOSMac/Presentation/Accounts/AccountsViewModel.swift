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

    var accounts: [Ledger] = []
    var banks: [Bank] = []
    var isLoading = false
    var editingAccount: Ledger?
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
        } catch {
            logger.logError(
                "Failed to load accounts: {error}",
                ["error": error.localizedDescription]
            )
        }
    }

    func updateAccount(_ account: Ledger) async {
        do {
            try await ledgerRepository.update(account)
            await loadAccounts()
            editingAccount = nil
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
            editingAccount = nil
        } catch {
            logger.logError(
                "Failed to convert account to card: {error}",
                ["accountId": account.id.uuidString, "error": error.localizedDescription]
            )
        }
    }
}

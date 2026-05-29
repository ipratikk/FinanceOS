//
//  AccountsViewModel.swift
//  FinanceOSMac
//
//  Created by Pratik Goel on 13/05/26.
//

import FinanceCore
import FinanceParsers
import FinanceUI
import Foundation
import Observation
import OSLog

@MainActor
@Observable
final class AccountsViewModel: AsyncLoadable, DeletableViewModel {
    private let ledgerRepository: LedgerRepository
    private let bankRepository: BankRepository
    private let transactionRepository: TransactionRepository
    private let balanceService: any AccountBalanceProtocol
    private let migrationService: any LedgerMigrationProtocol
    private let logger = FinanceLogger.userInterface

    struct AccountLedgerBalance {
        let netMinorUnits: Int64
        let latestPostedAt: Date?

        var formattedBalance: String {
            MoneyFormatting.formatBalance(minorUnits: netMinorUnits)
        }

        var formattedDate: String? {
            guard let date = latestPostedAt else { return nil }
            return FormatterCache.slashDate.string(from: date)
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
        transactionRepository: TransactionRepository,
        balanceService: (any AccountBalanceProtocol)? = nil,
        migrationService: (any LedgerMigrationProtocol)? = nil
    ) {
        self.ledgerRepository = ledgerRepository
        self.bankRepository = bankRepository
        self.transactionRepository = transactionRepository
        self.balanceService = balanceService ?? AccountBalanceService()
        self.migrationService = migrationService ?? LedgerMigrationService(
            ledgerRepository: ledgerRepository,
            transactionRepository: transactionRepository
        )
    }

    func loadAccounts() async {
        await withLoading(onError: { [self] error in
            logger.logError("Failed to load accounts: {error}", ["error": error.localizedDescription])
        }, {
            async let accounts = ledgerRepository.fetchLedgers(kind: .bankAccount)
            async let banks = bankRepository.fetchBanks()
            self.accounts = try await accounts
            self.banks = try await banks
            await loadBalances(for: self.accounts)
        })
    }

    private func loadBalances(for accounts: [Ledger]) async {
        var result: [UUID: AccountLedgerBalance] = [:]
        for account in accounts {
            do {
                let txns = try await transactionRepository.fetchTransactionsForLedger(account.id)
                guard !txns.isEmpty else { continue }
                let balanceDate = account.closingBalanceAsOf ?? txns.map(\.postedAt).max()
                let balanceMinorUnits = balanceService.computeBalance(account: account, transactions: txns)
                result[account.id] = AccountLedgerBalance(netMinorUnits: balanceMinorUnits, latestPostedAt: balanceDate)
            } catch {
                logger.logError(
                    "Failed to load transactions for account: {error}",
                    ["accountId": account.id.uuidString, "error": error.localizedDescription]
                )
            }
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
        await performDelete({
            logger.logDebug("Deleting account", ["accountId": id.uuidString])
            try await ledgerRepository.delete(id: id)
            logger.logInfo("Account deleted successfully", ["accountId": id.uuidString])
        }, onError: { [self] error in
            logger.logError(
                "Delete account failed: {error}",
                ["accountId": id.uuidString, "error": error.localizedDescription]
            )
        }, onSuccess: loadAccounts)
    }

    var groupedAccountsByBank: [(bankName: String, ledgers: [Ledger])] {
        let grouped = Dictionary(grouping: accounts) { ledger in
            banks.first { $0.id == ledger.bankId }?.name ?? "Unknown"
        }
        return grouped.map { (bankName: $0.key, ledgers: $0.value) }
            .sorted { $0.bankName < $1.bankName }
    }

    func statementSource(for ledger: Ledger) -> StatementSource? {
        let bank = banks.first { $0.id == ledger.bankId }
        guard let bankEnum = bank?.bank else { return nil }
        switch (bankEnum, ledger.kind) {
        case (.hdfc, .bankAccount): return .hdfcBank
        case (.hdfc, .creditCard): return .hdfcCard
        case (.icici, .bankAccount): return .iciciBank
        case (.icici, .creditCard): return .iciciCard
        case (.amex, _): return .amex
        default: return nil
        }
    }

    func convertToCard(_ account: Ledger) async {
        do {
            try await migrationService.convertToCard(account)
            await loadAccounts()
        } catch {
            logger.logError(
                "Failed to convert account to card: {error}",
                ["accountId": account.id.uuidString, "error": error.localizedDescription]
            )
        }
    }
}

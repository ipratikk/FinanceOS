//
//  AccountsViewModel.swift
//  FinanceOSMac
//
//  Created by Pratik Goel on 13/05/26.
//

import FinanceCore
import Foundation
import Observation

@Observable
final class AccountsViewModel {
    private let repository: AccountRepository
    private let bankRepository: BankRepository
    private let cardRepository: CardRepository
    private let transactionRepository: TransactionRepository

    var accounts: [Account] = []
    var banks: [Bank] = []
    var isLoading = false
    var editingAccount: Account?

    init(
        repository: AccountRepository,
        bankRepository: BankRepository,
        cardRepository: CardRepository,
        transactionRepository: TransactionRepository
    ) {
        self.repository = repository
        self.bankRepository = bankRepository
        self.cardRepository = cardRepository
        self.transactionRepository = transactionRepository
    }

    func loadAccounts() async {
        isLoading = true

        defer {
            isLoading = false
        }

        do {
            async let accounts = repository.fetchAccounts()
            async let banks = bankRepository.fetchBanks()
            self.accounts = try await accounts
            self.banks = try await banks
        } catch {
            print(error)
        }
    }

    func updateAccount(_ account: Account) async {
        do {
            try await repository.update(account)
            await loadAccounts()
            editingAccount = nil
        } catch {
            print(error)
        }
    }

    func deleteAccount(id: UUID) async {
        do {
            try await repository.delete(id: id)
            await loadAccounts()
        } catch {
            print(error)
        }
    }

    func convertToCard(_ account: Account) async {
        do {
            let card = Card(
                bankId: account.bankId,
                linkedAccountId: nil,
                cardName: account.accountName
            )
            try await cardRepository.insert(card)
            try await transactionRepository.migrateTransactions(fromAccount: account.id, toCard: card.id)
            try await repository.delete(id: account.id)
            await loadAccounts()
            editingAccount = nil
        } catch {
            print(error)
        }
    }
}

//
//  BanksViewModel.swift
//  FinanceOSMac
//
//  Created by Pratik Goel on 15/05/26.
//

import FinanceCore
import Foundation
import Observation

@Observable
final class BanksViewModel {
    private let repository: BankRepository
    private let ledgerRepository: LedgerRepository

    var banks: [Bank] = []
    var ledgersByBank: [UUID: [Ledger]] = [:]
    var isLoading = false
    var deleteError: String?

    init(
        repository: BankRepository,
        ledgerRepository: LedgerRepository
    ) {
        self.repository = repository
        self.ledgerRepository = ledgerRepository
    }

    func loadBanks() async {
        isLoading = true

        defer {
            isLoading = false
        }

        do {
            banks = try await repository.fetchBanks()
            var ledgerMap: [UUID: [Ledger]] = [:]
            for bank in banks {
                ledgerMap[bank.id] = try await ledgerRepository.fetchLedgers(bankId: bank.id)
            }
            ledgersByBank = ledgerMap
        } catch {
            FinanceLogger.ui.logError("Failed to load banks", caughtError: error, [:])
        }
    }

    func updateBank(_ bank: Bank) async {
        do {
            try await repository.update(bank)
            await loadBanks()
        } catch {
            FinanceLogger.ui.logError("Failed to load banks", caughtError: error, [:])
        }
    }

    func deleteBank(id: UUID) async {
        deleteError = nil
        do {
            try await repository.delete(id: id)
            await loadBanks()
        } catch {
            deleteError = error.localizedDescription
        }
    }
}

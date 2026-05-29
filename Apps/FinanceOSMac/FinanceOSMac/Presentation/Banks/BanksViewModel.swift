//
//  BanksViewModel.swift
//  FinanceOSMac
//
//  Created by Pratik Goel on 15/05/26.
//

import FinanceCore
import Foundation
import Observation

@MainActor
@Observable
final class BanksViewModel: AsyncLoadable, DeletableViewModel {
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
        await withLoading(onError: { error in
            FinanceLogger.userInterface.logError("Failed to load banks", caughtError: error, [:])
        }) {
            banks = try await repository.fetchBanks()
            var ledgerMap: [UUID: [Ledger]] = [:]
            for bank in banks {
                ledgerMap[bank.id] = try await ledgerRepository.fetchLedgers(bankId: bank.id)
            }
            ledgersByBank = ledgerMap
        }
    }

    func updateBank(_ bank: Bank) async {
        do {
            try await repository.update(bank)
            await loadBanks()
        } catch {
            FinanceLogger.userInterface.logError("Failed to load banks", caughtError: error, [:])
        }
    }

    func deleteBank(id: UUID) async {
        await performDelete({
            try await repository.delete(id: id)
        }, onSuccess: loadBanks)
    }
}

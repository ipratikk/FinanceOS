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

    var banks: [Bank] = []
    var isLoading = false
    var editingBank: Bank?
    var deleteError: String?

    init(
        repository: BankRepository
    ) {
        self.repository = repository
    }

    func loadBanks() async {
        isLoading = true

        defer {
            isLoading = false
        }

        do {
            banks = try await repository.fetchBanks()
        } catch {
            print(error)
        }
    }

    func updateBank(_ bank: Bank) async {
        do {
            try await repository.update(bank)
            await loadBanks()
            editingBank = nil
        } catch {
            print(error)
        }
    }

    func deleteBank(id: UUID) async {
        deleteError = nil
        do {
            try await repository.delete(id: id)
            await loadBanks()
            editingBank = nil
        } catch {
            deleteError = error.localizedDescription
        }
    }
}

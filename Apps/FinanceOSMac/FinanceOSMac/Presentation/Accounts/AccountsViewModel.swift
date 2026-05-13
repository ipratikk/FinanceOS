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

    var accounts: [Account] = []

    var isLoading = false

    init(
        repository: AccountRepository
    ) {
        self.repository = repository
    }

    func loadAccounts() async {
        isLoading = true

        defer {
            isLoading = false
        }

        do {
            accounts = try await repository
                .fetchAccounts()

        } catch {
            print(error)
        }
    }
}

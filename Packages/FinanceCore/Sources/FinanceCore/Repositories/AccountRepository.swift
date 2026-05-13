//
//  AccountRepository.swift
//  FinanceCore
//
//  Created by Pratik Goel on 13/05/26.
//

import Foundation

public protocol AccountRepository {
    func fetchAccounts() async throws -> [Account]
}

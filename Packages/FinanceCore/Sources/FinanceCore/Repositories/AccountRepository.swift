//
//  AccountRepository.swift
//  FinanceCore
//
//  Created by Pratik Goel on 13/05/26.
//

import Foundation

public protocol AccountRepository: Sendable {
    func fetchAccounts() async throws -> [Account]
    func insert(_ account: Account) async throws
    func update(_ account: Account) async throws
    func delete(id: UUID) async throws
}

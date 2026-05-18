//
//  BankRepository.swift
//  FinanceCore
//
//  Created by Pratik Goel on 15/05/26.
//

import Foundation

public protocol BankRepository: Sendable {
    func fetchBanks() async throws -> [Bank]
    func insert(_ bank: Bank) async throws
    func update(_ bank: Bank) async throws
    func delete(id: UUID) async throws
    func deleteAll() async throws
}

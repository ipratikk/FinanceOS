//
//  TransactionRepository.swift
//  FinanceCore
//
//  Created by Pratik Goel on 13/05/26.
//

import Foundation

public protocol TransactionRepository: Sendable {
    func fetchTransactions() async throws -> [Transaction]

    func fetchTransactionsForLedger(
        _ ledgerID: UUID
    ) async throws -> [Transaction]

    func fetchTransactionsForAccount(
        _ accountID: UUID
    ) async throws -> [Transaction]

    func fetchTransactionsForCard(
        _ cardID: UUID
    ) async throws -> [Transaction]

    func insertTransactions(
        _ transactions: [Transaction]
    ) async throws -> ImportResult

    func delete(id: UUID) async throws

    func migrateTransactions(fromCard cardID: UUID, toAccount accountID: UUID) async throws

    func migrateTransactions(fromAccount accountID: UUID, toCard cardID: UUID) async throws
}

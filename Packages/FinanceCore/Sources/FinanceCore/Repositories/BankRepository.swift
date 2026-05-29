//
//  BankRepository.swift
//  FinanceCore
//
//  Created by Pratik Goel on 15/05/26.
//

import Foundation

/// Persistence contract for `Bank` records. Banks are the top-level grouping entity;
/// deleting a bank should cascade or be guarded by the caller (no cascade logic here).
public protocol BankRepository: Sendable {
    /// Returns all banks in insertion order (no filtering applied).
    func fetchBanks() async throws -> [Bank]
    /// Inserts a new bank row; throws on primary key conflict.
    func insert(_ bank: Bank) async throws
    /// Updates all mutable fields on an existing bank row.
    func update(_ bank: Bank) async throws
    /// Hard-deletes a single bank by primary key.
    func delete(id: UUID) async throws
    /// Removes every bank row; used in tests and re-seed flows only.
    func deleteAll() async throws
}

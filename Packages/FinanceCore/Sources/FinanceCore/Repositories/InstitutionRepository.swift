//
//  InstitutionRepository.swift
//  FinanceCore
//
//  Created by Pratik Goel on 13/05/26.
//

import Foundation

public protocol InstitutionRepository: Sendable {
    func fetchInstitutions() async throws -> [Institution]
    func insert(_ institution: Institution) async throws
    func update(_ institution: Institution) async throws
    func delete(id: UUID) async throws
}

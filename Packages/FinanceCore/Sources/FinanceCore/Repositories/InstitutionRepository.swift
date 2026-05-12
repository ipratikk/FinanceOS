//
//  InstitutionRepository.swift
//  FinanceCore
//
//  Created by Pratik Goel on 13/05/26.
//

import Foundation

public protocol InstitutionRepository {
    func fetchInstitutions() async throws -> [Institution]
}

//
//  InstitutionsViewModel.swift
//  FinanceOSMac
//
//  Created by Pratik Goel on 13/05/26.
//

import FinanceCore
import Foundation
import Observation

@Observable
final class InstitutionsViewModel {
    private let repository: InstitutionRepository

    var institutions: [Institution] = []

    var isLoading = false

    init(
        repository: InstitutionRepository
    ) {
        self.repository = repository
    }

    func loadInstitutions() async {
        isLoading = true

        defer {
            isLoading = false
        }

        do {
            institutions = try await repository
                .fetchInstitutions()

        } catch {
            print(error)
        }
    }
}

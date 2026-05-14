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
    var editingInstitution: Institution?

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
            institutions = try await repository.fetchInstitutions()
        } catch {
            print(error)
        }
    }

    func updateInstitution(_ institution: Institution) async {
        do {
            try await repository.update(institution)
            await loadInstitutions()
            editingInstitution = nil
        } catch {
            print(error)
        }
    }

    func deleteInstitution(id: UUID) async {
        do {
            try await repository.delete(id: id)
            await loadInstitutions()
        } catch {
            print(error)
        }
    }
}

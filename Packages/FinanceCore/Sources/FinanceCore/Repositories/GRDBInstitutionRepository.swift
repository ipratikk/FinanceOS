//
//  GRDBInstitutionRepository.swift
//  FinanceCore
//
//  Created by Pratik Goel on 13/05/26.
//

import Foundation
import GRDB

public final class GRDBInstitutionRepository:
    InstitutionRepository
{
    private let dbQueue: DatabaseQueue

    public init(
        dbQueue: DatabaseQueue
    ) {
        self.dbQueue = dbQueue
    }

    public func fetchInstitutions() async throws -> [Institution] {
        try await dbQueue.read { database in
            try Institution.fetchAll(database)
        }
    }
}

//
//  DatabaseSeeder.swift
//  FinanceCore
//
//  Created by Pratik Goel on 13/05/26.
//

import Foundation
import GRDB

enum DatabaseSeeder {
    static func seedInstitutions(
        in database: Database
    ) throws {
        let existingInstitutionCount = try Institution
            .fetchCount(database)

        guard existingInstitutionCount == 0 else {
            return
        }

        let institutions = [
            Institution(name: "HDFC"),
            Institution(name: "ICICI"),
            Institution(name: "Amex"),
            Institution(name: "Scapia")
        ]

        for institution in institutions {
            try institution.insert(database)
        }

        FinanceLogger.database.info(
            "Seeded default institutions"
        )
    }
}

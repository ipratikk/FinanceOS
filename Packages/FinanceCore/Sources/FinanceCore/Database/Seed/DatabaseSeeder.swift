//
//  DatabaseSeeder.swift
//  FinanceCore
//
//  Created by Pratik Goel on 13/05/26.
//

import Foundation
import GRDB

enum DatabaseSeeder {
    static func seedBanks(
        in database: Database
    ) throws {
        let existingBankCount = try Bank
            .fetchCount(database)

        guard existingBankCount == 0 else {
            return
        }

        let banks = Banks.allCases.map { Bank(bank: $0) }

        for bank in banks {
            try bank.insert(database)
        }

        FinanceLogger.database.info(
            "Seeded default banks"
        )
    }
}

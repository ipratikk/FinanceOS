//
//  DatabaseSeeder.swift
//  FinanceCore
//
//  Created by Pratik Goel on 13/05/26.
//

import Foundation
import GRDB

/// Inserts default reference data required for foreign key integrity.
/// All seed operations are guarded with existence checks so they are safe to call on every launch.
enum DatabaseSeeder {
    /// Inserts one ``Bank`` row for each ``Banks`` case if the table is empty.
    /// Must run inside an open write transaction provided by the caller.
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

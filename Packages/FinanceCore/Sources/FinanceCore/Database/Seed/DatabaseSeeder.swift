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

        let banks = [
            Bank(name: "HDFC", providerType: .bank),
            Bank(name: "ICICI", providerType: .bank),
            Bank(name: "Amex", providerType: .credit),
            Bank(name: "Scapia", providerType: .bank)
        ]

        for bank in banks {
            try bank.insert(database)
        }

        FinanceLogger.database.info(
            "Seeded default banks"
        )
    }
}

//
//  AppMigration.swift
//  FinanceCore
//
//  Created by Pratik Goel on 13/05/26.
//

import Foundation
import GRDB

enum AppMigration {
    static func registerMigrations(
        in migrator: inout DatabaseMigrator
    ) {
        migrator.registerMigration("v1_create_all_tables") { database in
            FinanceLogger.migration.info("Running migration: v1_create_all_tables")

            try Bank.createTable(in: database)
            try Ledger.createTable(in: database)
            try Transaction.createTable(in: database)

            FinanceLogger.migration.info("v1: All tables created")
        }

        // v2 migration removed: columns already exist in initial schema (Ledger.createTable)
        // Fresh database creation includes closingBalance + closingBalanceAsOf

        migrator.registerMigration("v3_add_ledger_opening_balance") { database in
            let columns = try database.columns(in: "ledgers")
            guard !columns.contains(where: { $0.name == "openingBalance" }) else { return }
            try database.alter(table: "ledgers") { table in
                table.add(column: "openingBalance", .integer)
            }
        }

        migrator.registerMigration("v8_add_intelligence_fields") { database in
            let txnCols = try database.columns(in: "transactions")
            let hasCategory = txnCols.contains(where: { $0.name == "categoryId" })
            let hasMerchant = txnCols.contains(where: { $0.name == "merchantName" })
            try database.alter(table: "transactions") { table in
                if !hasCategory { table.add(column: "categoryId", .text) }
                if !hasMerchant { table.add(column: "merchantName", .text) }
            }
        }
    }
}

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
            try database.alter(table: "ledgers") { table in
                table.add(column: "openingBalance", .integer)
            }
        }
    }
}

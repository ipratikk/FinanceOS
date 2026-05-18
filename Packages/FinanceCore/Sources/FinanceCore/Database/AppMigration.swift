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

        migrator.registerMigration("v2_ledger_closing_balance") { database in
            FinanceLogger.migration.info("Running migration: v2_ledger_closing_balance")
            try database.alter(table: Ledger.databaseTableName) { table in
                table.add(column: "closingBalance", .integer)
                table.add(column: "closingBalanceAsOf", .datetime)
            }
            FinanceLogger.migration.info("v2: closingBalance + closingBalanceAsOf added to ledgers")
        }
    }
}

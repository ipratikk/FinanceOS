//
//  AppMigration.swift
//  FinanceCore
//
//  Created by Pratik Goel on 13/05/26.
//

import Foundation
import GRDB

/// Registers all schema migrations in version order with GRDB's ``DatabaseMigrator``.
/// Migrations are idempotent — guard checks prevent re-applying columns that already exist
/// (needed because v1 created the full schema for fresh installs while older builds only had subsets).
enum AppMigration {
    /// Registers every migration; called once by ``DatabaseManager`` during init.
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

        migrator.registerMigration("v9_add_transaction_closing_balance") { database in
            let cols = try database.columns(in: "transactions")
            guard !cols.contains(where: { $0.name == "closingBalanceMinorUnits" }) else { return }
            try database.alter(table: "transactions") { table in
                table.add(column: "closingBalanceMinorUnits", .integer)
            }
        }

        migrator.registerMigration("v10_add_intelligence_transaction_columns") { db in
            try AppMigration.addIntelligenceTransactionColumns(in: db)
        }

        migrator.registerMigration("v11_create_intelligence_persons") { db in
            try AppMigration.createIntelligencePersonsTable(in: db)
        }

        migrator.registerMigration("v12_create_intelligence_person_aliases") { db in
            try AppMigration.createIntelligencePersonAliasesTable(in: db)
        }
    }
}

// MARK: - Migration Helpers

private extension AppMigration {
    static func addIntelligenceTransactionColumns(in database: Database) throws {
        FinanceLogger.migration.info("Running migration: v10_add_intelligence_transaction_columns")
        let cols = try database.columns(in: "transactions")
        try database.alter(table: "transactions") { table in
            if !cols.contains(where: { $0.name == "intentId" }) {
                table.add(column: "intentId", .text)
            }
            if !cols.contains(where: { $0.name == "resolvedPersonId" }) {
                table.add(column: "resolvedPersonId", .text)
            }
            if !cols.contains(where: { $0.name == "intelligenceVersion" }) {
                table.add(column: "intelligenceVersion", .text)
            }
        }
    }

    static func createIntelligencePersonsTable(in database: Database) throws {
        FinanceLogger.migration.info("Running migration: v11_create_intelligence_persons")
        guard try !database.tableExists("intelligence_persons") else { return }
        try database.create(table: "intelligence_persons") { table in
            table.column("id", .text).primaryKey()
            table.column("canonicalName", .text).notNull()
            table.column("upiHandle", .text)
            table.column("transactionCount", .integer).notNull().defaults(to: 1)
            table.column("firstSeenAt", .datetime).notNull()
            table.column("lastSeenAt", .datetime).notNull()
        }
        try database.execute(sql: """
        CREATE UNIQUE INDEX IF NOT EXISTS idx_intel_persons_upi
        ON intelligence_persons(upiHandle) WHERE upiHandle IS NOT NULL
        """)
    }

    static func createIntelligencePersonAliasesTable(in database: Database) throws {
        FinanceLogger.migration.info("Running migration: v12_create_intelligence_person_aliases")
        guard try !database.tableExists("intelligence_person_aliases") else { return }
        try database.create(table: "intelligence_person_aliases") { table in
            table.column("id", .text).primaryKey()
            table.column("personId", .text).notNull()
                .references("intelligence_persons", column: "id", onDelete: .cascade)
            table.column("alias", .text).notNull()
        }
        try database.create(
            index: "idx_intel_aliases_alias",
            on: "intelligence_person_aliases",
            columns: ["alias"],
            unique: true
        )
        try database.create(
            index: "idx_intel_aliases_personId",
            on: "intelligence_person_aliases",
            columns: ["personId"]
        )
    }
}

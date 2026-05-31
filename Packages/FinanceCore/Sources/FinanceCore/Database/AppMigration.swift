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

        migrator.registerMigration("v13_create_knowledge_graph_nodes") { db in
            try AppMigration.createKnowledgeGraphNodesTable(in: db)
        }

        migrator.registerMigration("v14_create_knowledge_graph_edges") { db in
            try AppMigration.createKnowledgeGraphEdgesTable(in: db)
        }

        migrator.registerMigration("v15_create_relationships") { db in
            try AppMigration.createRelationshipsTable(in: db)
        }

        migrator.registerMigration("v16_create_recurring_patterns") { db in
            try AppMigration.createRecurringPatternsTable(in: db)
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

    static func createKnowledgeGraphNodesTable(in database: Database) throws {
        guard try !database.tableExists("knowledge_graph_nodes") else { return }
        try database.create(table: "knowledge_graph_nodes") { table in
            table.column("id", .text).primaryKey()
            table.column("nodeType", .text).notNull()
            table.column("externalId", .text).notNull()
            table.column("label", .text).notNull()
            table.column("properties", .text).notNull().defaults(to: "{}")
            table.column("createdAt", .datetime).notNull()
        }
        try database.create(
            index: "idx_graph_nodes_external",
            on: "knowledge_graph_nodes",
            columns: ["nodeType", "externalId"],
            unique: true
        )
        try database.create(
            index: "idx_graph_nodes_type",
            on: "knowledge_graph_nodes",
            columns: ["nodeType"]
        )
    }

    static func createKnowledgeGraphEdgesTable(in database: Database) throws {
        guard try !database.tableExists("knowledge_graph_edges") else { return }
        try database.create(table: "knowledge_graph_edges") { table in
            table.column("id", .text).primaryKey()
            table.column("fromNodeId", .text).notNull()
                .references("knowledge_graph_nodes", column: "id", onDelete: .cascade)
            table.column("toNodeId", .text).notNull()
                .references("knowledge_graph_nodes", column: "id", onDelete: .cascade)
            table.column("edgeType", .text).notNull()
            table.column("weight", .double).notNull().defaults(to: 1.0)
            table.column("observationCount", .integer).notNull().defaults(to: 1)
            table.column("lastObservedAt", .datetime).notNull()
            table.column("createdAt", .datetime).notNull()
        }
        try database.create(
            index: "idx_graph_edges_unique",
            on: "knowledge_graph_edges",
            columns: ["fromNodeId", "toNodeId", "edgeType"],
            unique: true
        )
        try database.create(
            index: "idx_graph_edges_from",
            on: "knowledge_graph_edges",
            columns: ["fromNodeId"]
        )
        try database.create(
            index: "idx_graph_edges_to",
            on: "knowledge_graph_edges",
            columns: ["toNodeId"]
        )
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

    static func createRelationshipsTable(in database: Database) throws {
        guard try !database.tableExists("relationships") else { return }
        try database.create(table: "relationships") { table in
            table.column("id", .text).primaryKey()
            table.column("fromPersonId", .text)
            table.column("toPersonId", .text)
            table.column("relationshipType", .text).notNull()
            table.column("confidence", .double).notNull().defaults(to: 0.0)
            table.column("evidenceCount", .integer).notNull().defaults(to: 0)
            table.column("inferredSignals", .text).notNull().defaults(to: "[]")
            table.column("createdAt", .datetime).notNull()
            table.column("updatedAt", .datetime).notNull()
        }
        try database.create(index: "idx_relationships_fromPersonId",
                            on: "relationships", columns: ["fromPersonId"])
        try database.create(index: "idx_relationships_toPersonId",
                            on: "relationships", columns: ["toPersonId"])
    }

    static func createRecurringPatternsTable(in database: Database) throws {
        guard try !database.tableExists("recurring_patterns") else { return }
        try database.create(table: "recurring_patterns") { table in
            table.column("id", .text).primaryKey()
            table.column("merchantKey", .text)
            table.column("personId", .text)
            table.column("categoryId", .text).notNull()
            table.column("intentId", .text).notNull()
            table.column("cadence", .text).notNull()
            table.column("averageAmountMinorUnits", .integer).notNull()
            table.column("amountVariancePercent", .double).notNull().defaults(to: 0.0)
            table.column("dayOfMonthHint", .integer)
            table.column("confidence", .double).notNull().defaults(to: 0.0)
            table.column("occurrenceCount", .integer).notNull().defaults(to: 0)
            table.column("lastSeenAt", .datetime).notNull()
            table.column("createdAt", .datetime).notNull()
        }
        try database.create(index: "idx_recurring_merchantKey",
                            on: "recurring_patterns", columns: ["merchantKey"])
        try database.create(index: "idx_recurring_personId",
                            on: "recurring_patterns", columns: ["personId"])
    }
}

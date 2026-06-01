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
    // swiftlint:disable:next function_body_length
    static func registerMigrations(
        in migrator: inout DatabaseMigrator
    ) {
        migrator.registerMigration("v1_create_all_tables") { db in
            try AppMigration.createAllTables(in: db)
        }

        // v2 removed: columns exist in initial schema

        migrator.registerMigration("v3_add_ledger_opening_balance") { db in
            try AppMigration.addLedgerOpeningBalance(in: db)
        }

        migrator.registerMigration("v8_add_intelligence_fields") { db in
            try AppMigration.addIntelligenceFields(in: db)
        }

        migrator.registerMigration("v9_add_transaction_closing_balance") { db in
            try AppMigration.addTransactionClosingBalance(in: db)
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

        migrator.registerMigration("v17_create_intelligence_model_metadata") { db in
            try AppMigration.createIntelligenceModelMetadataTable(in: db)
        }

        migrator.registerMigration("v18_dedup_recurring_patterns") { db in
            // RecurringDetector created fresh UUIDs each run; save() used upsert-by-pk
            // which always inserted. Keep the earliest row per (merchantKey, personId, cadence).
            try db.execute(sql: """
                DELETE FROM recurring_patterns WHERE rowid NOT IN (
                    SELECT MIN(rowid) FROM recurring_patterns
                    GROUP BY COALESCE(merchantKey, ''), COALESCE(personId, ''), cadence
                )
            """)
        }

        migrator.registerMigration("v20_create_intelligence_inference_events") { db in
            try AppMigration.createIntelligenceInferenceEventsTable(in: db)
        }

        migrator.registerMigration("v21_expand_intelligence_model_metadata") { db in
            try AppMigration.expandIntelligenceModelMetadataTable(in: db)
        }

        migrator.registerMigration("v22_add_relationship_verification_state") { db in
            let cols = try db.columns(in: "relationships")
            guard !cols.contains(where: { $0.name == "verificationState" }) else { return }
            try db.alter(table: "relationships") { table in
                table.add(column: "verificationState", .text).notNull().defaults(to: "inferred")
            }
        }

        migrator.registerMigration("v19_dedup_relationships_and_patterns") { db in
            // Relationships: same upsert-by-pk bug. Keep earliest per (toPersonId, relationshipType).
            try db.execute(sql: """
                DELETE FROM relationships WHERE rowid NOT IN (
                    SELECT MIN(rowid) FROM relationships
                    GROUP BY COALESCE(toPersonId, ''), relationshipType
                )
            """)
            // Recurring patterns: re-dedup by (merchantKey, cadence) ignoring personId
            // so merchant+person dual entries collapse into one row.
            try db.execute(sql: """
                DELETE FROM recurring_patterns WHERE rowid NOT IN (
                    SELECT MIN(rowid) FROM recurring_patterns
                    GROUP BY COALESCE(merchantKey, COALESCE(personId, '')), cadence
                )
            """)
            // Purge stale recurringPattern graph nodes accumulated from old UUID-keyed runs.
            try db.execute(sql: """
                DELETE FROM knowledge_graph_nodes WHERE nodeType = 'recurringPattern'
            """)
        }
    }
}

// MARK: - Migration Helpers

private extension AppMigration {
    static func createAllTables(in database: Database) throws {
        FinanceLogger.migration.info("Running migration: v1_create_all_tables")
        try Bank.createTable(in: database)
        try Ledger.createTable(in: database)
        try Transaction.createTable(in: database)
        FinanceLogger.migration.info("v1: All tables created")
    }

    static func addLedgerOpeningBalance(in database: Database) throws {
        let columns = try database.columns(in: "ledgers")
        guard !columns.contains(where: { $0.name == "openingBalance" }) else { return }
        try database.alter(table: "ledgers") { table in
            table.add(column: "openingBalance", .integer)
        }
    }

    static func addIntelligenceFields(in database: Database) throws {
        let txnCols = try database.columns(in: "transactions")
        let hasCategory = txnCols.contains(where: { $0.name == "categoryId" })
        let hasMerchant = txnCols.contains(where: { $0.name == "merchantName" })
        try database.alter(table: "transactions") { table in
            if !hasCategory { table.add(column: "categoryId", .text) }
            if !hasMerchant { table.add(column: "merchantName", .text) }
        }
    }

    static func addTransactionClosingBalance(in database: Database) throws {
        let cols = try database.columns(in: "transactions")
        guard !cols.contains(where: { $0.name == "closingBalanceMinorUnits" }) else { return }
        try database.alter(table: "transactions") { table in
            table.add(column: "closingBalanceMinorUnits", .integer)
        }
    }

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
        try database.create(
            index: "idx_relationships_fromPersonId",
            on: "relationships",
            columns: ["fromPersonId"]
        )
        try database.create(
            index: "idx_relationships_toPersonId",
            on: "relationships",
            columns: ["toPersonId"]
        )
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
        try database.create(
            index: "idx_recurring_merchantKey",
            on: "recurring_patterns",
            columns: ["merchantKey"]
        )
        try database.create(
            index: "idx_recurring_personId",
            on: "recurring_patterns",
            columns: ["personId"]
        )
    }

    static func createIntelligenceModelMetadataTable(in database: Database) throws {
        guard try !database.tableExists("intelligence_model_metadata") else { return }
        try database.create(table: "intelligence_model_metadata") { table in
            table.column("id", .text).primaryKey()
            table.column("modelName", .text).notNull().unique()
            table.column("modelVersion", .text).notNull()
            table.column("accuracy", .double)
            table.column("trainedAt", .datetime)
            table.column("sampleCount", .integer)
            table.column("isActive", .integer).notNull().defaults(to: 1)
            table.column("notes", .text)
        }
    }

    static func expandIntelligenceModelMetadataTable(in database: Database) throws {
        // v17 had UNIQUE on modelName (wrong) and was missing many columns — drop and recreate.
        if try database.tableExists("intelligence_model_metadata") {
            try database.drop(table: "intelligence_model_metadata")
        }
        try database.create(table: "intelligence_model_metadata") { table in
            table.column("id", .text).primaryKey()
            table.column("modelName", .text).notNull()
            table.column("modelType", .text).notNull()
            table.column("modelVersion", .text).notNull()
            table.column("trainedAt", .datetime).notNull()
            table.column("trainingExampleCount", .integer).notNull()
            table.column("validationExampleCount", .integer)
            table.column("featureVersion", .text)
            table.column("configVersion", .text)
            table.column("accuracy", .double)
            table.column("precisionMacro", .double)
            table.column("recallMacro", .double)
            table.column("f1Macro", .double)
            table.column("brierScore", .double)
            table.column("expectedCalibrationError", .double)
            table.column("confusionMatrixJson", .text)
            table.column("trainingDataHash", .text)
            table.column("notes", .text)
        }
        try database.create(index: "idx_model_metadata_name", on: "intelligence_model_metadata", columns: ["modelName"])
        try database.create(
            index: "idx_model_metadata_trained_at", on: "intelligence_model_metadata", columns: ["trainedAt"]
        )
    }

    static func createIntelligenceInferenceEventsTable(in database: Database) throws {
        guard try !database.tableExists("intelligence_inference_events") else { return }
        try database.create(table: "intelligence_inference_events") { table in
            table.column("id", .text).primaryKey()
            table.column("transactionId", .text)
            table.column("stage", .text).notNull()
            table.column("source", .text).notNull()
            table.column("ruleId", .text)
            table.column("modelId", .text)
            table.column("modelVersion", .text)
            table.column("configVersion", .text)
            table.column("inputHash", .text)
            table.column("outputLabel", .text)
            table.column("outputIntent", .text)
            table.column("confidence", .double)
            table.column("confidenceKind", .text).notNull()
                .check(sql: "confidenceKind IN ('deterministic','calibrated_probability'," +
                    "'uncalibrated_score','heuristic_ordinal','not_applicable')")
            table.column("debugJSON", .text)
            table.column("createdAt", .datetime).notNull()
        }
        try database.create(
            index: "idx_inference_events_txn",
            on: "intelligence_inference_events",
            columns: ["transactionId"]
        )
        try database.create(
            index: "idx_inference_events_stage",
            on: "intelligence_inference_events",
            columns: ["stage"]
        )
        try database.create(
            index: "idx_inference_events_created",
            on: "intelligence_inference_events",
            columns: ["createdAt"]
        )
    }
}

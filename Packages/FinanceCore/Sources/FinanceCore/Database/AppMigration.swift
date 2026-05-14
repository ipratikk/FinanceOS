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
        migrator.registerMigration("v1_initial") { database in
            FinanceLogger.migration.info("Running migration: v1_initial")

            try database.execute(sql: """
                CREATE TABLE institutions (
                    id TEXT PRIMARY KEY,
                    name TEXT NOT NULL
                )
            """)
        }

        migrator.registerMigration("v2_accounts") { database in
            FinanceLogger.migration.info("Running migration: v2_accounts")

            try database.execute(sql: """
                CREATE TABLE accounts (
                    id TEXT PRIMARY KEY,
                    institutionID TEXT NOT NULL REFERENCES institutions(id) ON DELETE CASCADE,
                    name TEXT NOT NULL,
                    nickname TEXT NOT NULL DEFAULT ''
                )
            """)
            try database.execute(sql: "CREATE INDEX idx_accounts_institutionID ON accounts(institutionID)")
        }

        migrator.registerMigration("v3_cards_split") { database in
            FinanceLogger.migration.info("Running migration: v3_cards_split")

            try database.execute(sql: """
                CREATE TABLE cards (
                    id TEXT PRIMARY KEY,
                    institutionID TEXT NOT NULL REFERENCES institutions(id) ON DELETE CASCADE,
                    accountID TEXT REFERENCES accounts(id) ON DELETE SET NULL,
                    name TEXT NOT NULL,
                    nickname TEXT NOT NULL DEFAULT '',
                    last4 TEXT NOT NULL DEFAULT ''
                )
            """)
            try database.execute(sql: "CREATE INDEX idx_cards_institutionID ON cards(institutionID)")
            try database.execute(sql: "CREATE INDEX idx_cards_accountID ON cards(accountID)")

            // Fetch legacy accounts and institutions using raw SQL
            let legacyAccountRows = try database.fetch(Row.self, sql: "SELECT id, name FROM accounts")
            let institutionRows = try database.fetch(Row.self, sql: "SELECT id, name FROM institutions")

            let institutionIDsByName = Dictionary(
                uniqueKeysWithValues: institutionRows.compactMap { row in
                    guard let name: String = row["name"], let id: String = row["id"] else {
                        return nil
                    }
                    return (name, UUID(uuidString: id) ?? UUID())
                }
            )

            let preservedAccounts = legacyAccountRows.filter { row in
                guard let name: String = row["name"] else { return false }
                return !legacyCardNameMappings.keys.contains(name)
            }

            try database.execute(sql: "DELETE FROM accounts")

            for row in preservedAccounts {
                guard let id: String = row["id"], let name: String = row["name"], let institutionID: String = row["institutionID"] else {
                    continue
                }
                try database.execute(sql:
                    "INSERT INTO accounts (id, institutionID, name, nickname) VALUES (?, ?, ?, '')",
                    arguments: [id, institutionID, name]
                )
            }

            let seededAccountRows = try seedDefaultAccounts(
                in: database,
                institutionIDsByName: institutionIDsByName
            )

            let legacyCardRows = legacyAccountRows.compactMap { row in
                guard let name: String = row["name"], let mapping = legacyCardNameMappings[name] else {
                    return nil
                }
                return (id: row["id"] as? String, institutionID: row["institutionID"] as? String, mapping: mapping)
            }

            try database.execute(sql: "DELETE FROM cards")

            for row in legacyCardRows {
                guard let id = row.id, let institutionID = row.institutionID else { continue }

                let linkedAccountID = row.mapping.linkedAccountInstitutionName
                    .flatMap { seededAccountRows[$0]?.id.uuidString }

                let linkedAccountIDParam: String? = linkedAccountID
                try database.execute(sql:
                    "INSERT INTO cards (id, institutionID, accountID, name, nickname, last4) VALUES (?, ?, ?, ?, '', '')",
                    arguments: [id, institutionID, linkedAccountIDParam as Any, row.mapping.canonicalName]
                )
            }
        }

        migrator.registerMigration("v4_transactions") { database in
            FinanceLogger.migration.info("Running migration: v4_transactions")

            try Transaction.createTable(
                in: database
            )
        }

        migrator.registerMigration("v5_transaction_sourceFingerprint_unique") { database in
            FinanceLogger.migration.info("Running migration: v5_transaction_sourceFingerprint_unique")

            try database.execute(sql: """
                CREATE UNIQUE INDEX IF NOT EXISTS idx_transactions_sourceFingerprint
                ON transactions(sourceFingerprint)
                WHERE sourceFingerprint IS NOT NULL
            """)
        }

        migrator.registerMigration("v6_bank_model_update") { database in
            FinanceLogger.migration.info("Running migration: v6_bank_model_update")

            // 1. Create banks table (from institutions)
            try database.create(table: "banks") { t in
                t.column("id", .text).primaryKey()
                t.column("name", .text).notNull()
                t.column("providerType", .text).notNull().defaults(to: "bank")
            }
            try database.execute(sql: "INSERT INTO banks (id, name, providerType) SELECT id, name, 'bank' FROM institutions")

            // 2. Recreate accounts with new columns
            try database.create(table: "accounts_new") { t in
                t.column("id", .text).primaryKey()
                t.column("bankId", .text).notNull().indexed().references("banks", column: "id", onDelete: .cascade)
                t.column("accountName", .text).notNull()
                t.column("accountLast4", .text).notNull().defaults(to: "")
                t.column("ownerName", .text).notNull().defaults(to: "")
                t.column("accountType", .text).notNull().defaults(to: "savings")
                t.column("nickname", .text).notNull().defaults(to: "")
            }
            try database.execute(sql: """
                INSERT INTO accounts_new (id, bankId, accountName, accountLast4, ownerName, accountType, nickname)
                SELECT id, institutionID, name, '', '', 'savings', nickname FROM accounts
            """)
            try database.drop(table: "accounts")
            try database.rename(table: "accounts_new", to: "accounts")

            // 3. Recreate cards with new columns
            try database.create(table: "cards_new") { t in
                t.column("id", .text).primaryKey()
                t.column("bankId", .text).notNull().indexed().references("banks", column: "id", onDelete: .cascade)
                t.column("linkedAccountId", .text).indexed().references("accounts", column: "id", onDelete: .setNull)
                t.column("cardName", .text).notNull()
                t.column("cardLast4", .text).notNull().defaults(to: "")
                t.column("cardType", .text).notNull().defaults(to: "other")
                t.column("nickname", .text).notNull().defaults(to: "")
            }
            try database.execute(sql: """
                INSERT INTO cards_new (id, bankId, linkedAccountId, cardName, cardLast4, cardType, nickname)
                SELECT id, institutionID, accountID, name, last4, 'other', nickname FROM cards
            """)
            try database.drop(table: "cards")
            try database.rename(table: "cards_new", to: "cards")

            // 4. Drop institutions (data already in banks)
            try database.drop(table: "institutions")
        }
    }
}

private extension AppMigration {
    static let legacyCardNameMappings: [String: (
        institutionName: String,
        canonicalName: String,
        linkedAccountInstitutionName: String?
    )] = [
        "HDFC Platinum Card": ("HDFC", "HDFC Regalia", "HDFC"),
        "HDFC Regalia Gold": ("HDFC", "HDFC Regalia", "HDFC"),
        "HDFC Regalia": ("HDFC", "HDFC Regalia", "HDFC"),
        "ICICI Savings Account": ("ICICI", "ICICI Coral", "ICICI"),
        "ICICI Coral": ("ICICI", "ICICI Coral", "ICICI"),
        "ICICI Amazon Pay": ("ICICI", "ICICI Amazon Pay", "ICICI"),
        "Amex Gold Card": ("Amex", "American Express Platinum Travel", nil),
        "American Express Platinum Travel": ("Amex", "American Express Platinum Travel", nil),
        "Scapia Travel Card": ("Scapia", "Scapia", nil),
        "Scapia": ("Scapia", "Scapia", nil)
    ]

    static func seedDefaultAccounts(
        in database: Database,
        institutionIDsByName: [String: UUID]
    ) throws -> [String: (id: UUID, name: String)] {
        let definitions = [
            ("HDFC", "HDFC Bank Account"),
            ("ICICI", "ICICI Bank Account")
        ]

        var seededAccounts: [String: (id: UUID, name: String)] = [:]

        for (institutionName, accountName) in definitions {
            guard let institutionID = institutionIDsByName[institutionName] else {
                continue
            }

            let accountID = UUID()
            try database.execute(sql:
                "INSERT INTO accounts (id, institutionID, name, nickname) VALUES (?, ?, ?, '')",
                arguments: [accountID.uuidString, institutionID.uuidString, accountName]
            )
            seededAccounts[institutionName] = (id: accountID, name: accountName)
        }

        return seededAccounts
    }
}

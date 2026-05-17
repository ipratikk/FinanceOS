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

            // Legacy data migration handled by raw SQL
            // For v3, just create the tables; existing data (if any) will be handled by later migrations
        }

        migrator.registerMigration("v4_transactions") { database in
            FinanceLogger.migration.info("Running migration: v4_transactions")

            try database.create(table: "transactions") { table in
                table.column("id", .text).primaryKey()
                table.column("accountID", .text).indexed()
                table.column("cardID", .text).indexed()
                table.column("postedAt", .datetime).notNull().indexed()
                table.column("description", .text).notNull()
                table.column("amountMinorUnits", .integer).notNull()
                table.column("currencyCode", .text).notNull()
                table.column("transactionType", .text).notNull().defaults(to: "debit")
                table.column("sourceFingerprint", .text)
                table.check(
                    sql: """
                    (
                        ("accountID" IS NOT NULL AND "cardID" IS NULL)
                        OR
                        ("accountID" IS NULL AND "cardID" IS NOT NULL)
                    )
                    """
                )
            }
        }

        migrator.registerMigration("v5_transaction_sourceFingerprint_unique") { database in
            FinanceLogger.migration.info("Running migration: v5_transaction_sourceFingerprint_unique")

            try database.execute(sql: """
                CREATE UNIQUE INDEX IF NOT EXISTS idx_transactions_sourceFingerprint
                ON transactions(sourceFingerprint)
                WHERE sourceFingerprint IS NOT NULL
            """)
        }

        migrator.registerMigration("v5b_fix_transaction_uniqueness") { database in
            FinanceLogger.migration.info("Running migration: v5b_fix_transaction_uniqueness")

            // Drop the overly-broad UNIQUE INDEX that causes false conflicts
            try database.execute(sql: """
                DROP INDEX IF EXISTS idx_transactions_sourceFingerprint
            """)

            // Create scoped indexes to deduplicate within each account/card separately
            try database.execute(sql: """
                CREATE UNIQUE INDEX IF NOT EXISTS idx_transactions_account_fingerprint
                ON transactions(accountID, sourceFingerprint)
                WHERE accountID IS NOT NULL AND cardID IS NULL AND sourceFingerprint IS NOT NULL
            """)

            try database.execute(sql: """
                CREATE UNIQUE INDEX IF NOT EXISTS idx_transactions_card_fingerprint
                ON transactions(cardID, sourceFingerprint)
                WHERE accountID IS NULL AND cardID IS NOT NULL AND sourceFingerprint IS NOT NULL
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
            try database
                .execute(sql: "INSERT INTO banks (id, name, providerType) SELECT id, name, 'bank' FROM institutions")

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

        migrator.registerMigration("v7_ledger_unification") { database in
            FinanceLogger.migration.info("v7: Starting ledger unification")

            FinanceLogger.migration.info("v7: Creating ledgers table")
            try database.execute(sql: """
                CREATE TABLE ledgers (
                    id TEXT PRIMARY KEY,
                    bankId TEXT NOT NULL REFERENCES banks(id) ON DELETE CASCADE,
                    kind TEXT NOT NULL,
                    displayName TEXT NOT NULL,
                    last4 TEXT NOT NULL DEFAULT '',
                    nickname TEXT NOT NULL DEFAULT '',
                    ownerName TEXT NOT NULL DEFAULT '',
                    createdAt DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
                    accountType TEXT,
                    cardType TEXT,
                    cardProduct TEXT,
                    linkedLedgerId TEXT REFERENCES ledgers(id) ON DELETE CASCADE,
                    isArchived INTEGER NOT NULL DEFAULT 0,
                    CHECK (kind IN ('bankAccount','creditCard','loan','wallet','crypto','investment'))
                )
            """)
            FinanceLogger.migration.info("v7: Creating ledger indexes")
            try database.execute(sql: "CREATE INDEX idx_ledgers_bankId ON ledgers(bankId)")
            try database.execute(sql: "CREATE INDEX idx_ledgers_kind ON ledgers(kind)")
            try database.execute(sql: "CREATE INDEX idx_ledgers_linkedLedgerId ON ledgers(linkedLedgerId)")
            try database.execute(sql: "CREATE INDEX idx_ledgers_bank_kind ON ledgers(bankId, kind)")

            FinanceLogger.migration.info("v7: Backfilling from accounts")
            try database.execute(sql: """
                INSERT INTO ledgers
                (id, bankId, kind, displayName, last4, nickname, ownerName, createdAt,
                 accountType, cardType, cardProduct, linkedLedgerId, isArchived)
                SELECT id, bankId, 'bankAccount', accountName, accountLast4, nickname,
                       ownerName, CURRENT_TIMESTAMP, accountType, NULL, NULL, NULL, 0
                FROM accounts
            """)

            FinanceLogger.migration.info("v7: Backfilling from cards")
            try database.execute(sql: """
                INSERT INTO ledgers
                (id, bankId, kind, displayName, last4, nickname, ownerName, createdAt,
                 accountType, cardType, cardProduct, linkedLedgerId, isArchived)
                SELECT id, bankId, 'creditCard', cardName, cardLast4, nickname, '',
                       CURRENT_TIMESTAMP, NULL, cardType, '', linkedAccountId, 0
                FROM cards
            """)

            FinanceLogger.migration.info("v7: Adding ledgerId column to transactions")
            try database.execute(sql: """
                ALTER TABLE transactions ADD COLUMN ledgerId TEXT REFERENCES ledgers(id) ON DELETE CASCADE
            """)

            FinanceLogger.migration.info("v7: Populating ledgerId from accountID/cardID")
            try database.execute(sql: """
                UPDATE transactions SET ledgerId = COALESCE(accountID, cardID)
            """)

            FinanceLogger.migration.info("v7: Ledger unification complete")
        }

        migrator.registerMigration("v8_fix_ledger_cascade_delete") { _ in
            FinanceLogger.migration.info("Running migration: v8_fix_ledger_cascade_delete")

            // v7 now creates ledgers with CASCADE constraint from the start
            // This migration is now a no-op but kept for migration history
            FinanceLogger.migration.info("v8: No-op migration (CASCADE constraint fixed in v7)")
        }

        migrator.registerMigration("v9_add_bin_column") { database in
            FinanceLogger.migration.info("Running migration: v9_add_bin_column")

            try database.execute(sql: """
                ALTER TABLE ledgers ADD COLUMN bin TEXT
            """)

            FinanceLogger.migration.info("v9: Added bin column to ledgers")
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
}

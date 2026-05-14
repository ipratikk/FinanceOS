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

            try Institution.createTable(
                in: database
            )
        }

        migrator.registerMigration("v2_accounts") { database in
            FinanceLogger.migration.info("Running migration: v2_accounts")

            try Account.createTable(
                in: database
            )
        }

        migrator.registerMigration("v3_cards_split") { database in
            FinanceLogger.migration.info("Running migration: v3_cards_split")

            try Card.createTable(
                in: database
            )

            let legacyAccounts = try Account
                .fetchAll(database)

            let institutions = try Institution
                .fetchAll(database)

            let institutionIDsByName = Dictionary(
                uniqueKeysWithValues: institutions.map { institution in
                    (institution.name, institution.id)
                }
            )

            let preservedAccounts = legacyAccounts.filter { account in
                !legacyCardNameMappings.keys.contains(account.name)
            }

            try Account.deleteAll(database)

            for account in preservedAccounts {
                try account.insert(database)
            }

            let seededAccounts = try seedDefaultAccounts(
                in: database,
                institutionIDsByName: institutionIDsByName
            )

            let legacyCards = legacyAccounts.compactMap { account in
                legacyCard(from: account, seededAccounts: seededAccounts)
            }

            try Card.deleteAll(database)

            for card in legacyCards {
                try card.insert(database)
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
    ) throws -> [String: Account] {
        let definitions = [
            ("HDFC", "HDFC Bank Account"),
            ("ICICI", "ICICI Bank Account")
        ]

        var seededAccounts: [String: Account] = [:]

        for (institutionName, accountName) in definitions {
            guard let institutionID = institutionIDsByName[institutionName] else {
                continue
            }

            let account = Account(
                institutionID: institutionID,
                name: accountName
            )

            try account.insert(database)
            seededAccounts[institutionName] = account
        }

        return seededAccounts
    }

    static func legacyCard(
        from account: Account,
        seededAccounts: [String: Account]
    ) -> Card? {
        guard let mapping = legacyCardNameMappings[account.name] else {
            return nil
        }

        let linkedAccountID = mapping.linkedAccountInstitutionName.flatMap { institutionName in
            seededAccounts[institutionName]?.id
        }

        return Card(
            id: account.id,
            institutionID: account.institutionID,
            accountID: linkedAccountID,
            name: mapping.canonicalName
        )
    }
}

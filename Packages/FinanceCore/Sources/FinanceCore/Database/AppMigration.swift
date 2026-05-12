//
//  AppMigration.swift
//  FinanceCore
//
//  Created by Pratik Goel on 13/05/26.
//

import GRDB

enum AppMigration {
    static func registerMigrations(
        in migrator: inout DatabaseMigrator
    ) {
        FinanceLogger.migration.info("Running migration: v1_initial")

        migrator.registerMigration("v1_initial") { database in
            try Institution.createTable(
                in: database
            )
        }
    }
}

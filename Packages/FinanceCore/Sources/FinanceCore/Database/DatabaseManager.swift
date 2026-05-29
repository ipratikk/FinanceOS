//
//  DatabaseManager.swift
//  FinanceCore
//
//  Created by Pratik Goel on 13/05/26.
//

import Foundation
import GRDB

/// Owns the SQLite connection pool and drives schema migrations at startup.
/// `@unchecked Sendable` is safe because `dbQueue` is itself thread-safe and `init` is private.
public final class DatabaseManager: @unchecked Sendable {
    /// Singleton. A `fatalError` is intentional — an unusable DB is unrecoverable at launch.
    public static let shared: DatabaseManager = {
        do {
            return try DatabaseManager()
        } catch {
            fatalError("Database initialization failed: \(error)")
        }
    }()

    /// The GRDB queue passed to all repository implementations; never used directly by ViewModels.
    public let dbQueue: DatabaseQueue

    private init() throws {
        let databaseURL = try Self.makeDatabaseURL()

        FinanceLogger.database.info(
            "Database initialized at: \(databaseURL.path)"
        )

        var config = Configuration()
        config.prepareDatabase { database in
            try database.execute(sql: "PRAGMA foreign_keys = ON")
        }

        dbQueue = try DatabaseQueue(
            path: databaseURL.path,
            configuration: config
        )

        try migrator.migrate(dbQueue)

        try seedDatabase()
    }
}

private extension DatabaseManager {
    /// Resolves or creates the `FinanceOS/finance.sqlite` file in Application Support.
    static func makeDatabaseURL() throws -> URL {
        let applicationSupport = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )

        let directory = applicationSupport
            .appendingPathComponent(
                "FinanceOS",
                isDirectory: true
            )

        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )

        return directory
            .appendingPathComponent("finance.sqlite")
    }
}

private extension DatabaseManager {
    /// Builds a fresh ``DatabaseMigrator`` with all registered migrations; called once during init.
    var migrator: DatabaseMigrator {
        var migrator = DatabaseMigrator()

        AppMigration.registerMigrations(
            in: &migrator
        )

        return migrator
    }
}

private extension DatabaseManager {
    func seedDatabase() throws {
        try dbQueue.write { database in
            // Seed default banks (required for foreign key constraints)
            try DatabaseSeeder.seedBanks(in: database)
        }
    }
}

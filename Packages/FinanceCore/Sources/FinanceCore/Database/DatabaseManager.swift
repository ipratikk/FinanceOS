//
//  DatabaseManager.swift
//  FinanceCore
//
//  Created by Pratik Goel on 13/05/26.
//

import Foundation
import GRDB

public final class DatabaseManager: @unchecked Sendable {
    public static let shared: DatabaseManager = {
        do {
            return try DatabaseManager()
        } catch {
            fatalError("Database initialization failed: \(error)")
        }
    }()

    public let dbQueue: DatabaseQueue

    private init() throws {
        let databaseURL = try Self.makeDatabaseURL()

        FinanceLogger.database.info(
            "Database initialized at: \(databaseURL.path)"
        )

        dbQueue = try DatabaseQueue(
            path: databaseURL.path
        )

        try migrator.migrate(dbQueue)
    }
}

private extension DatabaseManager {
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
    var migrator: DatabaseMigrator {
        var migrator = DatabaseMigrator()

        AppMigration.registerMigrations(
            in: &migrator
        )

        return migrator
    }
}

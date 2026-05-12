//
//  FinanceLogger.swift
//  FinanceCore
//
//  Created by Pratik Goel on 13/05/26.
//

import OSLog

public enum FinanceLogger {
    public static let database = Logger(
        subsystem: subsystem,
        category: "Database"
    )

    public static let migration = Logger(
        subsystem: subsystem,
        category: "Migration"
    )

    public static let importPipeline = Logger(
        subsystem: subsystem,
        category: "ImportPipeline"
    )

    public static let parsing = Logger(
        subsystem: subsystem,
        category: "Parsing"
    )

    public static let sync = Logger(
        subsystem: subsystem,
        category: "Sync"
    )

    private static let subsystem = "com.pratik.FinanceOS"
}

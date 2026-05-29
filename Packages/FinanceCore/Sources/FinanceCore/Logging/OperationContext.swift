//
//  OperationContext.swift
//  FinanceCore
//
//  Created by Pratik Goel on 17/05/26.
//

import Foundation

/// Lightweight correlation token for a named operation; used to tie log lines together across async boundaries.
/// Create one at the start of an operation and pass `elapsedSeconds()` into log messages on completion.
public struct OperationContext: Sendable {
    /// Unique ID for correlating log lines that belong to the same operation.
    public let id: String
    /// Human-readable label written into log messages (e.g. "parse:Statement.pdf").
    public let name: String
    /// Wall-clock start time; used to compute elapsed duration.
    public let startTime: Date

    public init(id: String = UUID().uuidString, name: String) {
        self.id = id
        self.name = name
        startTime = Date()
    }

    /// Pre-built context for a full statement import session.
    public static func importSession() -> OperationContext {
        OperationContext(name: "import")
    }

    /// Pre-built context scoped to parsing a single file.
    public static func parseFile(_ fileName: String) -> OperationContext {
        OperationContext(name: "parse:\(fileName)")
    }

    /// Pre-built context scoped to a specific schema migration version.
    public static func databaseMigration(_ version: String) -> OperationContext {
        OperationContext(name: "migration:\(version)")
    }

    /// Seconds elapsed since the context was created.
    public func duration() -> TimeInterval {
        Date().timeIntervalSince(startTime)
    }

    /// Human-readable elapsed time string (e.g. "0.123s") for log messages.
    public func elapsedSeconds() -> String {
        String(format: "%.3fs", duration())
    }
}

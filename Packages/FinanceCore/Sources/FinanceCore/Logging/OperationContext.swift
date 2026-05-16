//
//  OperationContext.swift
//  FinanceCore
//
//  Created by Pratik Goel on 17/05/26.
//

import Foundation

public struct OperationContext: Sendable {
    public let id: String
    public let name: String
    public let startTime: Date

    public init(id: String = UUID().uuidString, name: String) {
        self.id = id
        self.name = name
        startTime = Date()
    }

    public static func importSession() -> OperationContext {
        OperationContext(name: "import")
    }

    public static func parseFile(_ fileName: String) -> OperationContext {
        OperationContext(name: "parse:\(fileName)")
    }

    public static func databaseMigration(_ version: String) -> OperationContext {
        OperationContext(name: "migration:\(version)")
    }

    public func duration() -> TimeInterval {
        Date().timeIntervalSince(startTime)
    }

    public func elapsedSeconds() -> String {
        String(format: "%.3fs", duration())
    }
}

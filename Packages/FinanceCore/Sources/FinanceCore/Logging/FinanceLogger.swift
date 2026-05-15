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

public extension Logger {
    /// Log with static string and attribute dictionary to avoid OSLog privacy marker concatenation issues.
    /// Use placeholders in format: "Message {key1} and {key2}"
    /// Then call: logger.logInfo("Message {key1} and {key2}", ["key1": value1, "key2": value2])
    func logInfo(
        _ staticMsg: StaticString,
        _ attrs: [String: CustomStringConvertible] = [:]
    ) {
        var msg = staticMsg.withUTF8Buffer { String(decoding: $0, as: UTF8.self) }
        for (key, value) in attrs {
            msg = msg.replacingOccurrences(of: "{\(key)}", with: String(describing: value))
        }
        info("\(msg, privacy: .public)")
    }

    /// Debug version of logInfo.
    func logDebug(
        _ staticMsg: StaticString,
        _ attrs: [String: CustomStringConvertible] = [:]
    ) {
        var msg = staticMsg.withUTF8Buffer { String(decoding: $0, as: UTF8.self) }
        for (key, value) in attrs {
            msg = msg.replacingOccurrences(of: "{\(key)}", with: String(describing: value))
        }
        debug("\(msg, privacy: .public)")
    }
}

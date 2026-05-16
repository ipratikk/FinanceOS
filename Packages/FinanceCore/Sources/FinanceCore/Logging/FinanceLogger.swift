//
//  FinanceLogger.swift
//  FinanceCore
//
//  Created by Pratik Goel on 13/05/26.
//

import OSLog

public enum FinanceLogger {
    public static let ui = Logger(
        subsystem: subsystem,
        category: "UI"
    )

    public static let accounts = Logger(
        subsystem: subsystem,
        category: "Accounts"
    )

    public static let transactions = Logger(
        subsystem: subsystem,
        category: "Transactions"
    )

    public static let importPipeline = Logger(
        subsystem: subsystem,
        category: "ImportPipeline"
    )

    public static let parsing = Logger(
        subsystem: subsystem,
        category: "Parsing"
    )

    public static let database = Logger(
        subsystem: subsystem,
        category: "Database"
    )

    public static let migration = Logger(
        subsystem: subsystem,
        category: "Migration"
    )

    public static let repository = Logger(
        subsystem: subsystem,
        category: "Repository"
    )

    public static let performance = Logger(
        subsystem: subsystem,
        category: "Performance"
    )

    public static let sync = Logger(
        subsystem: subsystem,
        category: "Sync"
    )

    public static let security = Logger(
        subsystem: subsystem,
        category: "Security"
    )

    private static let subsystem = "com.pratik.FinanceOS"
}

public extension Logger {
    /// Format message with metadata dictionary, replacing {key} placeholders.
    /// Messages are logged with .public privacy level.
    /// Example: logger.logTrace("Parsing {file}", ["file": fileName])
    func logTrace(
        _ staticMsg: StaticString,
        _ metadata: [String: CustomStringConvertible] = [:]
    ) {
        let msg = _formatMessage(staticMsg, metadata)
        trace("\(msg, privacy: .public)")
    }

    func logDebug(
        _ staticMsg: StaticString,
        _ metadata: [String: CustomStringConvertible] = [:]
    ) {
        let msg = _formatMessage(staticMsg, metadata)
        debug("\(msg, privacy: .public)")
    }

    func logInfo(
        _ staticMsg: StaticString,
        _ metadata: [String: CustomStringConvertible] = [:]
    ) {
        let msg = _formatMessage(staticMsg, metadata)
        info("\(msg, privacy: .public)")
    }

    func logNotice(
        _ staticMsg: StaticString,
        _ metadata: [String: CustomStringConvertible] = [:]
    ) {
        let msg = _formatMessage(staticMsg, metadata)
        notice("\(msg, privacy: .public)")
    }

    func logWarning(
        _ staticMsg: StaticString,
        _ metadata: [String: CustomStringConvertible] = [:]
    ) {
        let msg = _formatMessage(staticMsg, metadata)
        warning("\(msg, privacy: .public)")
    }

    func logError(
        _ staticMsg: StaticString,
        _ metadata: [String: CustomStringConvertible] = [:]
    ) {
        let msg = _formatMessage(staticMsg, metadata)
        error("\(msg, privacy: .public)")
    }

    func logCritical(
        _ staticMsg: StaticString,
        _ metadata: [String: CustomStringConvertible] = [:]
    ) {
        let msg = _formatMessage(staticMsg, metadata)
        critical("\(msg, privacy: .public)")
    }

    private func _formatMessage(
        _ staticMsg: StaticString,
        _ metadata: [String: CustomStringConvertible]
    ) -> String {
        var msg = staticMsg.withUTF8Buffer { String(decoding: $0, as: UTF8.self) }
        for (key, value) in metadata {
            msg = msg.replacingOccurrences(of: "{\(key)}", with: String(describing: value))
        }
        return msg
    }
}

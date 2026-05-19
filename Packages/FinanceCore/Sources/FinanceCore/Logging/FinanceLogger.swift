//
//  FinanceLogger.swift
//  FinanceCore
//
//  Created by Pratik Goel on 13/05/26.
//

import Foundation
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
    // MARK: - Production-Grade Logging with Context

    /// Log trace level with full context (file, function, line, metadata).
    /// Example: logger.logTrace("Fetching user", file: #file, function: #function, line: #line, ["userID": "123"])
    func logTrace(
        _ message: StaticString,
        file: String = #file,
        function: String = #function,
        line: Int = #line,
        _ attributes: [String: CustomStringConvertible] = [:]
    ) {
        let formatted = _formatContextualMessage(
            message,
            file: file,
            function: function,
            line: line,
            attributes: attributes
        )
        trace("\(formatted)")
    }

    func logDebug(
        _ message: StaticString,
        file: String = #file,
        function: String = #function,
        line: Int = #line,
        _ attributes: [String: CustomStringConvertible] = [:]
    ) {
        let formatted = _formatContextualMessage(
            message,
            file: file,
            function: function,
            line: line,
            attributes: attributes
        )
        debug("\(formatted)")
    }

    func logInfo(
        _ message: StaticString,
        file: String = #file,
        function: String = #function,
        line: Int = #line,
        _ attributes: [String: CustomStringConvertible] = [:]
    ) {
        let formatted = _formatContextualMessage(
            message,
            file: file,
            function: function,
            line: line,
            attributes: attributes
        )
        info("\(formatted)")
    }

    func logNotice(
        _ message: StaticString,
        file: String = #file,
        function: String = #function,
        line: Int = #line,
        _ attributes: [String: CustomStringConvertible] = [:]
    ) {
        let formatted = _formatContextualMessage(
            message,
            file: file,
            function: function,
            line: line,
            attributes: attributes
        )
        notice("\(formatted)")
    }

    func logWarning(
        _ message: StaticString,
        file: String = #file,
        function: String = #function,
        line: Int = #line,
        _ attributes: [String: CustomStringConvertible] = [:]
    ) {
        let formatted = _formatContextualMessage(
            message,
            file: file,
            function: function,
            line: line,
            attributes: attributes
        )
        warning("\(formatted)")
    }

    func logError(
        _ message: StaticString,
        caughtError: Error? = nil,
        file: String = #file,
        function: String = #function,
        line: Int = #line,
        _ attributes: [String: CustomStringConvertible] = [:]
    ) {
        var mutableAttrs = attributes
        if let err = caughtError {
            mutableAttrs["error"] = err.localizedDescription
            let nsError = err as NSError
            mutableAttrs["errorCode"] = nsError.code
            mutableAttrs["errorDomain"] = nsError.domain
        }
        let formatted = _formatContextualMessage(
            message,
            file: file,
            function: function,
            line: line,
            attributes: mutableAttrs
        )
        error("\(formatted)")
    }

    func logCritical(
        _ message: StaticString,
        file: String = #file,
        function: String = #function,
        line: Int = #line,
        _ attributes: [String: CustomStringConvertible] = [:]
    ) {
        let formatted = _formatContextualMessage(
            message,
            file: file,
            function: function,
            line: line,
            attributes: attributes
        )
        critical("\(formatted)")
    }

    // MARK: - Private Formatting

    private func _formatContextualMessage(
        _ message: StaticString,
        file: String,
        function: String,
        line: Int,
        attributes: [String: CustomStringConvertible]
    ) -> String {
        // Extract filename from full path
        let filename = (file as NSString).lastPathComponent

        // Convert StaticString to String
        var msg = message.withUTF8Buffer { String(decoding: $0, as: UTF8.self) }

        // Replace {key} placeholders with attribute values
        for (key, value) in attributes {
            msg = msg.replacingOccurrences(of: "{\(key)}", with: String(describing: value))
        }

        // Get thread info for concurrency debugging
        let threadName = Thread.current.isMainThread ? "main" : "bg"

        // Format with context: [file:line function] message {attrs}
        let contextualMsg = "[\(filename):\(line) \(function) <\(threadName)>] \(msg)"

        // Add remaining attributes that weren't interpolated
        if !attributes.isEmpty {
            let unusedAttrs = attributes
                .map { "\($0.key)=\($0.value)" }
                .joined(separator: " ")
            return "\(contextualMsg) {\(unusedAttrs)}"
        }

        return contextualMsg
    }
}

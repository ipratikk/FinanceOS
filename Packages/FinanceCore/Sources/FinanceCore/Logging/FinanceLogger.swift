//
//  FinanceLogger.swift
//  FinanceCore
//
//  Created by Pratik Goel on 13/05/26.
//

import Foundation
import OSLog

/// Namespace of pre-configured `OSLog.Logger` instances, one per architectural layer.
/// All logging in FinanceOS must route through one of these loggers so Console.app filters work correctly.
public enum FinanceLogger {
    /// UI events, navigation, and user interaction.
    public static let userInterface = Logger(
        subsystem: subsystem,
        category: "UI"
    )

    /// Account and ledger CRUD operations.
    public static let accounts = Logger(
        subsystem: subsystem,
        category: "Accounts"
    )

    /// Transaction fetch, mutation, and deduplication.
    public static let transactions = Logger(
        subsystem: subsystem,
        category: "Transactions"
    )

    /// Statement file → parsed transactions → repository write pipeline.
    public static let importPipeline = Logger(
        subsystem: subsystem,
        category: "ImportPipeline"
    )

    /// Bank-specific parser internals and regex matching.
    public static let parsing = Logger(
        subsystem: subsystem,
        category: "Parsing"
    )

    /// Raw GRDB / SQLite query execution.
    public static let database = Logger(
        subsystem: subsystem,
        category: "Database"
    )

    /// Schema migration steps.
    public static let migration = Logger(
        subsystem: subsystem,
        category: "Migration"
    )

    /// Repository-layer read/write operations above raw SQL.
    public static let repository = Logger(
        subsystem: subsystem,
        category: "Repository"
    )

    /// Timing instrumentation via `PerformanceTimer`.
    public static let performance = Logger(
        subsystem: subsystem,
        category: "Performance"
    )

    /// Reserved for future cloud-sync operations.
    public static let sync = Logger(
        subsystem: subsystem,
        category: "Sync"
    )

    /// Keychain and data-protection events.
    public static let security = Logger(
        subsystem: subsystem,
        category: "Security"
    )

    private static let subsystem = "com.pratik.FinanceOS"
}

public extension Logger {
    // MARK: - Production-Grade Logging with Context

    /// Emits a trace-level log with source location and key-value attributes interpolated into the message.
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

    /// Emits a debug-level log with source location and key-value attributes.
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

    /// Emits an info-level log; use for significant lifecycle events (import started, migration complete).
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

    /// Emits a notice-level log; use for non-critical anomalies worth surfacing in production logs.
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

    /// Emits a warning-level log; indicates recoverable problems that may degrade correctness.
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

    /// Emits an error-level log; automatically appends `localizedDescription`, `errorCode`, and `errorDomain`
    /// from `caughtError` when provided.
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

    /// Emits a critical-level log; reserved for unrecoverable failures (database corruption, missing resource).
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
        var msg = message.withUTF8Buffer { String(bytes: $0, encoding: .utf8) ?? "" }

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

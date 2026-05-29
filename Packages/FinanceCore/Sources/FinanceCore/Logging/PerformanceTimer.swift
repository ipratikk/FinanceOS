//
//  PerformanceTimer.swift
//  FinanceCore
//
//  Created by Pratik Goel on 17/05/26.
//

import OSLog

/// Stopwatch helper that emits elapsed-time log lines at named stages of an operation.
/// Inject the appropriate `FinanceLogger.*` channel at the call site; this type owns no logger of its own category.
public struct PerformanceTimer: Sendable {
    private let logger: Logger
    private let operation: String
    private let startTime: Date

    public init(
        logger: Logger,
        operation: String
    ) {
        self.logger = logger
        self.operation = operation
        startTime = Date()
    }

    /// Logs a debug-level checkpoint at `stage` with elapsed time since the timer was created.
    public func mark(_ stage: String) {
        let elapsed = _formatDuration(Date().timeIntervalSince(startTime))
        let msg = "\(operation): \(stage) completed in \(elapsed)"
        logger.debug("\(msg, privacy: .public)")
    }

    /// Logs an info-level completion line with total elapsed time and an optional result summary.
    public func complete(result: String = "success") {
        let elapsed = _formatDuration(Date().timeIntervalSince(startTime))
        let msg = "\(operation) completed in \(elapsed): \(result)"
        logger.info("\(msg, privacy: .public)")
    }

    private func _formatDuration(_ interval: TimeInterval) -> String {
        String(format: "%.3fs", interval)
    }
}

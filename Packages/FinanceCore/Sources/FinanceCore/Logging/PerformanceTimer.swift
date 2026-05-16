//
//  PerformanceTimer.swift
//  FinanceCore
//
//  Created by Pratik Goel on 17/05/26.
//

import OSLog

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

    public func mark(_ stage: String) {
        let elapsed = _formatDuration(Date().timeIntervalSince(startTime))
        let msg = "\(operation): \(stage) completed in \(elapsed)"
        logger.debug("\(msg, privacy: .public)")
    }

    public func complete(result: String = "success") {
        let elapsed = _formatDuration(Date().timeIntervalSince(startTime))
        let msg = "\(operation) completed in \(elapsed): \(result)"
        logger.info("\(msg, privacy: .public)")
    }

    private func _formatDuration(_ interval: TimeInterval) -> String {
        String(format: "%.3fs", interval)
    }
}

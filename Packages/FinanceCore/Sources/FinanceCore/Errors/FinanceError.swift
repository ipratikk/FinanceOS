//
//  FinanceError.swift
//  FinanceCore
//
//  Created by Pratik Goel on 17/05/26.
//

import Foundation

/// Broad domain that produced an error; used for routing, logging, and analytics tagging.
public enum ErrorCategory: String, Sendable {
    case parsing
    case importOperation = "import"
    case database
    case validation
    case repository
    case fileAccess = "file_access"
    /// Bank/institution name matching failures during statement detection.
    case matching
    case sync
    case network
    case unknown
}

/// Indicates urgency and how the error should be surfaced to the user or logged.
public enum ErrorSeverity: String, Sendable {
    /// Informational; expected outcome (e.g. duplicate skipped).
    case info
    /// Non-fatal; user action may resolve it.
    case warning
    /// Operation failed; user should retry or inspect the file.
    case error
    /// Data integrity at risk; may require support intervention.
    case critical
}

/// Base protocol for all domain errors in FinanceOS.
/// Conforming types must supply both a developer-facing `technicalMessage` and a
/// localised `userMessage` suitable for display in the UI.
public protocol FinanceError: LocalizedError {
    var category: ErrorCategory { get }
    var severity: ErrorSeverity { get }
    /// Full technical description for logging and crash reporting.
    var technicalMessage: String { get }
    /// Short, user-facing description shown in error banners or alerts.
    var userMessage: String { get }
    var recoverySuggestion: String? { get }
    /// When true, the operation that produced the error may succeed if retried.
    var isRetryable: Bool { get }
    var underlyingError: Error? { get }
}

public extension FinanceError {
    var errorDescription: String? {
        userMessage
    }

    var failureReason: String? {
        technicalMessage
    }

    var recoverySuggestion: String? {
        nil
    }

    var underlyingError: Error? {
        nil
    }
}

// MARK: - Bank Errors

/// Thrown when the parser detects a bank name that cannot be matched to a known ``Banks`` case.
public struct BankResolutionError: FinanceError, Sendable {
    public let category = ErrorCategory.matching
    public let severity: ErrorSeverity
    public let technicalMessage: String
    public let userMessage: String
    public let recoverySuggestion: String?
    public let isRetryable = true

    public init(detected: String) {
        technicalMessage = "Could not match detected bank '\(detected)' to known institution"
        userMessage = "Unable to identify bank '\(detected)'. Please select one from the list."
        recoverySuggestion = "Select a bank manually from the available options"
        severity = .error
    }
}

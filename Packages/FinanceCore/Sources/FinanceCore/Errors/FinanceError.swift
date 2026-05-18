//
//  FinanceError.swift
//  FinanceCore
//
//  Created by Pratik Goel on 17/05/26.
//

import Foundation

public enum ErrorCategory: String, Sendable {
    case parsing
    case importOperation = "import"
    case database
    case validation
    case repository
    case fileAccess = "file_access"
    case matching
    case sync
    case network
    case unknown
}

public enum ErrorSeverity: String, Sendable {
    case info
    case warning
    case error
    case critical
}

public protocol FinanceError: LocalizedError {
    var category: ErrorCategory { get }
    var severity: ErrorSeverity { get }
    var technicalMessage: String { get }
    var userMessage: String { get }
    var recoverySuggestion: String? { get }
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

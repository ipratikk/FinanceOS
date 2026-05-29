//
//  ValidationError.swift
//  FinanceCore
//
//  Created by Pratik Goel on 17/05/26.
//

import Foundation

/// Errors produced when user-supplied or parsed data fails business-rule checks before persistence.
/// All cases are non-retryable — the input itself must be corrected.
public enum ValidationError: FinanceError {
    case invalidData(field: String, value: String, reason: String)
    case missingRequiredField(String)
    /// A numeric or date value falls outside the permitted range (e.g. negative amount).
    case invalidRange(field: String, value: String, range: String)

    public var category: ErrorCategory {
        .validation
    }

    public var severity: ErrorSeverity {
        .warning
    }

    public var technicalMessage: String {
        switch self {
        case let .invalidData(field, value, reason):
            return "Invalid \(field): '\(value)' - \(reason)"
        case let .missingRequiredField(field):
            return "Missing required field: \(field)"
        case let .invalidRange(field, value, range):
            return "\(field) value '\(value)' outside valid range: \(range)"
        }
    }

    public var userMessage: String {
        switch self {
        case let .invalidData(field, _, reason):
            return "\(field) is invalid: \(reason)"
        case let .missingRequiredField(field):
            return "\(field) is required."
        case let .invalidRange(field, _, range):
            return "\(field) must be within \(range)."
        }
    }

    public var isRetryable: Bool {
        false
    }
}

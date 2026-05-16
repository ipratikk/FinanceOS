//
//  ValidationError.swift
//  FinanceCore
//
//  Created by Pratik Goel on 17/05/26.
//

import Foundation

public enum ValidationError: FinanceError {
    case invalidData(field: String, value: String, reason: String)
    case missingRequiredField(String)
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

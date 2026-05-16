//
//  ParsingError.swift
//  FinanceCore
//
//  Created by Pratik Goel on 17/05/26.
//

import Foundation

public enum ParsingError: FinanceError {
    case unsupportedFormat(String)
    case missingColumn(String)
    case invalidDate(String, pattern: String)
    case invalidAmount(String)
    case malformedStructure(String)
    case detectionFailed(String)

    public var category: ErrorCategory {
        .parsing
    }

    public var severity: ErrorSeverity {
        switch self {
        case .unsupportedFormat, .missingColumn, .detectionFailed:
            return .error
        case .invalidDate, .invalidAmount:
            return .warning
        case .malformedStructure:
            return .error
        }
    }

    public var technicalMessage: String {
        switch self {
        case let .unsupportedFormat(format):
            return "Parser not available for format: \(format)"
        case let .missingColumn(col):
            return "Required column missing: \(col)"
        case let .invalidDate(value, pattern):
            return "Invalid date '\(value)' for pattern '\(pattern)'"
        case let .invalidAmount(value):
            return "Invalid amount value: \(value)"
        case let .malformedStructure(desc):
            return "File structure malformed: \(desc)"
        case let .detectionFailed(reason):
            return "Statement detection failed: \(reason)"
        }
    }

    public var userMessage: String {
        switch self {
        case let .unsupportedFormat(format):
            return "File format '\(format)' is not supported. Try CSV, XLSX, or PDF."
        case let .missingColumn(col):
            return "Statement is missing required column: \(col)"
        case let .invalidDate(value, _):
            return "Date '\(value)' format is not recognized."
        case let .invalidAmount(value):
            return "Amount '\(value)' is not a valid number."
        case let .malformedStructure(desc):
            return "File structure is invalid: \(desc)"
        case .detectionFailed:
            return "Unable to detect the statement format. Check the file and try again."
        }
    }

    public var recoverySuggestion: String? {
        "Check the file format and try again with a valid statement file."
    }

    public var isRetryable: Bool {
        false
    }
}

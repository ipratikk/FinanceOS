//
//  ParsingError.swift
//  FinanceCore
//
//  Created by Pratik Goel on 17/05/26.
//

import Foundation

/// Errors thrown by FinanceParsers when a statement file cannot be read or normalised.
/// All cases are non-retryable — the user must supply a corrected file.
public enum ParsingError: FinanceError {
    /// File extension or internal structure does not match any registered parser.
    case unsupportedFormat(String)
    /// A column required by the parser is absent from the statement header.
    case missingColumn(String)
    /// A date cell value could not be parsed with the expected format pattern.
    case invalidDate(String, pattern: String)
    case invalidAmount(String)
    /// The file's overall structure (row count, header position, etc.) is unexpected.
    case malformedStructure(String)
    /// Auto-detection heuristics could not determine the bank or statement variant.
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

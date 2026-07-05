//
//  TransactionImportError.swift
//  FinanceCore
//
//  Created by Pratik Goel on 13/05/26.
//

import Foundation

/// Errors thrown during statement import and parsing.
public enum TransactionImportError: Error, CustomStringConvertible {
    /// The file extension or format identifier is not handled by any registered parser.
    case unsupportedFormat(String)
    /// A required CSV column header was absent from the file.
    case missingRequiredColumn(String)
    /// A date string could not be parsed with any of the institution's expected formats.
    case invalidDate(String)
    /// An amount string could not be converted to a numeric value.
    case invalidAmount(String)
    /// The file structure is inconsistent or corrupt in a way that prevents parsing.
    case malformedFile(String)
    /// A required platform capability (e.g. CoreXLSX on non-Darwin) is unavailable.
    case platformUnavailable(String)
    /// The file is encrypted and a password must be supplied via `ParseOptions`.
    case passwordProtected(String)

    public var description: String {
        switch self {
        case let .unsupportedFormat(format):
            return "Unsupported file format: \(format)"
        case let .missingRequiredColumn(column):
            return "Missing required column: \(column)"
        case let .invalidDate(value):
            return "Invalid date format: \(value)"
        case let .invalidAmount(value):
            return "Invalid amount: \(value)"
        case let .malformedFile(description):
            return "File is malformed: \(description)"
        case let .platformUnavailable(description):
            return description
        case let .passwordProtected(filename):
            return "Password required for: \(filename)"
        }
    }

    /// Alias for `description`; suitable for display in the import UI.
    public var userMessage: String {
        description
    }
}

//
//  TransactionImportError.swift
//  FinanceCore
//
//  Created by Pratik Goel on 13/05/26.
//

import FinanceParsers
import Foundation

public enum TransactionImportError: Error, LocalizedError {
    case unsupportedFormat(StatementFileFormat)
    case missingRequiredColumn(String)
    case invalidDate(String)
    case invalidAmount(String)
    case malformedFile(String)
    case platformUnavailable(String)
    case passwordProtected(String)

    public var errorDescription: String? {
        switch self {
        case let .unsupportedFormat(format):
            return "The file format \"\(format.rawValue)\" is not supported. Please use CSV or XLSX files."
        case let .missingRequiredColumn(column):
            return "Required column not found: \(column). Please ensure your file contains this column."
        case let .invalidDate(value):
            return "Unable to parse date: \(value). Supported formats: yyyy-MM-dd, dd/MM/yyyy, MM/dd/yyyy, dd-MM-yyyy, dd MMM yyyy, dd MMM yy"
        case let .invalidAmount(value):
            return "Unable to parse amount: \(value). Please ensure amounts are valid numbers."
        case let .malformedFile(description):
            return "The file appears to be corrupted or malformed: \(description)"
        case let .platformUnavailable(description):
            return description
        case let .passwordProtected(filename):
            return "The PDF file \"\(filename)\" is password-protected. Please enter the password to continue."
        }
    }

    public var failureReason: String? {
        switch self {
        case .unsupportedFormat:
            return "File format not supported"
        case .missingRequiredColumn:
            return "Required column missing"
        case .invalidDate:
            return "Date format not recognized"
        case .invalidAmount:
            return "Amount format not recognized"
        case .malformedFile:
            return "File is malformed"
        case .platformUnavailable:
            return "Feature unavailable on this platform"
        case .passwordProtected:
            return "PDF file is password-protected"
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .unsupportedFormat:
            return "Export your statement as CSV or XLSX from your bank."
        case .missingRequiredColumn:
            return "Check the file contains required columns like date, description, and amount."
        case .invalidDate:
            return "Ensure dates in your file are in a standard format."
        case .invalidAmount:
            return "Ensure all amounts are valid numbers, optionally with currency symbols."
        case .malformedFile:
            return "Try exporting the file again or download the latest version."
        case .platformUnavailable:
            return "Try using a different file format or import method."
        case .passwordProtected:
            return "Enter the password for the PDF file. You can save it to Keychain for future use."
        }
    }
}

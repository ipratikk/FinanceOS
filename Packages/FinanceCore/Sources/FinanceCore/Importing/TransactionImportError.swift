//
//  TransactionImportError.swift
//  FinanceCore
//
//  Created by Pratik Goel on 13/05/26.
//

import Foundation

public enum TransactionImportError: Error {
    case unsupportedFormat(StatementFileFormat)
    case missingRequiredColumn(String)
    case invalidDate(String)
    case invalidAmount(String)
    case malformedFile(String)
    case platformUnavailable(String)
}

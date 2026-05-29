//
//  ErrorMapper.swift
//  FinanceCore
//
//  Created by Pratik Goel on 17/05/26.
//

import Foundation
import GRDB

/// Translates raw Swift/GRDB/Foundation errors into strongly-typed ``FinanceError`` values.
/// Call sites should catch `Error` broadly and pass it through `map(_:)` before propagating.
public enum ErrorMapper {
    /// Maps any `Error` to a ``FinanceError``, preserving already-typed errors as-is.
    public static func map(_ error: Error) -> FinanceError {
        if let financeError = error as? FinanceError {
            return financeError
        }

        if let dbError = error as? GRDB.DatabaseError {
            return mapDatabaseError(dbError)
        }

        if let decodingError = error as? DecodingError {
            return mapDecodingError(decodingError)
        }

        let nsError = error as NSError
        return mapNSError(nsError)
    }

    private static func mapDatabaseError(_ error: GRDB.DatabaseError) -> FinanceError {
        let msg = error.message ?? "Unknown database error"

        switch error.resultCode {
        case .SQLITE_CONSTRAINT:
            return DatabaseError.constraintViolation(
                table: "unknown",
                constraint: msg
            )
        case .SQLITE_IOERR:
            return DatabaseError.queryFailed(sql: "unknown", reason: "I/O error: \(msg)")
        case .SQLITE_BUSY:
            return DatabaseError.queryFailed(sql: "unknown", reason: "Database is busy")
        default:
            return DatabaseError.queryFailed(sql: "unknown", reason: msg)
        }
    }

    private static func mapDecodingError(_ error: DecodingError) -> FinanceError {
        let msg = String(describing: error)
        return ParsingError.malformedStructure(msg)
    }

    private static func mapNSError(_ error: NSError) -> FinanceError {
        if error.domain == NSCocoaErrorDomain {
            switch error.code {
            case NSFileNoSuchFileError:
                let path = error.userInfo[NSFilePathErrorKey] as? String ?? "unknown"
                return FileAccessError.fileNotFound(path: path)
            case NSFileReadNoPermissionError:
                let path = error.userInfo[NSFilePathErrorKey] as? String ?? "unknown"
                return FileAccessError.permissionDenied(path: path)
            default:
                return FileAccessError.readFailed(
                    path: error.userInfo[NSFilePathErrorKey] as? String ?? "unknown",
                    reason: error.localizedDescription
                )
            }
        }

        return UnknownFinanceError(underlying: error)
    }
}

/// Wraps an unrecognised `Error` that ``ErrorMapper`` could not map to a specific domain type.
public struct UnknownFinanceError: FinanceError {
    public let underlying: Error

    public var category: ErrorCategory {
        .unknown
    }

    public var severity: ErrorSeverity {
        .error
    }

    public var technicalMessage: String {
        String(describing: underlying)
    }

    public var userMessage: String {
        "An unexpected error occurred. Please try again or contact support."
    }

    public var isRetryable: Bool {
        false
    }

    public var underlyingError: Error? {
        underlying
    }
}

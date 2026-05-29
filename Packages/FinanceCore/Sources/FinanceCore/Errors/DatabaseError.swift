//
//  DatabaseError.swift
//  FinanceCore
//
//  Created by Pratik Goel on 17/05/26.
//

import Foundation

/// Errors produced by the GRDB/SQLite layer; surfaced through ``ErrorMapper`` from raw GRDB errors.
public enum DatabaseError: FinanceError {
    /// A schema migration did not complete; the DB version is indeterminate.
    case migrationFailed(version: String, reason: String)
    /// A UNIQUE or FOREIGN KEY constraint was violated; usually signals a duplicate import attempt.
    case constraintViolation(table: String, constraint: String)
    case queryFailed(sql: String, reason: String)
    case corruptionDetected(String)

    public var category: ErrorCategory {
        .database
    }

    public var severity: ErrorSeverity {
        switch self {
        case .constraintViolation:
            return .warning
        case .queryFailed:
            return .error
        case .migrationFailed, .corruptionDetected:
            return .critical
        }
    }

    public var technicalMessage: String {
        switch self {
        case let .migrationFailed(version, reason):
            return "Migration \(version) failed: \(reason)"
        case let .constraintViolation(table, constraint):
            return "Constraint violation on \(table)(\(constraint))"
        case let .queryFailed(sql, reason):
            return "Query failed: \(reason). SQL: \(sql)"
        case let .corruptionDetected(desc):
            return "Database corruption detected: \(desc)"
        }
    }

    public var userMessage: String {
        switch self {
        case let .constraintViolation(_, constraint):
            return "Data conflicts with existing records (\(constraint)). Import was skipped."
        case .queryFailed:
            return "Database operation failed. Please try again or restart the app."
        case let .migrationFailed(version, _):
            return "Database update (v\(version)) failed. Please restart the app or contact support."
        case .corruptionDetected:
            return "Database is corrupted. Please contact support."
        }
    }

    public var isRetryable: Bool {
        switch self {
        case .constraintViolation, .corruptionDetected:
            return false
        case .queryFailed, .migrationFailed:
            return true
        }
    }
}

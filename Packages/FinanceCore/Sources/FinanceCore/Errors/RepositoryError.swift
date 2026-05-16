//
//  RepositoryError.swift
//  FinanceCore
//
//  Created by Pratik Goel on 17/05/26.
//

import Foundation

public enum RepositoryError: FinanceError {
    case notFound(entity: String, id: String)
    case queryFailed(entity: String, reason: String)
    case insertFailed(entity: String, reason: String)
    case updateFailed(entity: String, id: String, reason: String)
    case deleteFailed(entity: String, id: String, reason: String)

    public var category: ErrorCategory {
        .repository
    }

    public var severity: ErrorSeverity {
        switch self {
        case .notFound:
            return .info
        default:
            return .error
        }
    }

    public var technicalMessage: String {
        switch self {
        case let .notFound(entity, id):
            return "\(entity) not found: \(id)"
        case let .queryFailed(entity, reason):
            return "Query for \(entity) failed: \(reason)"
        case let .insertFailed(entity, reason):
            return "Insert \(entity) failed: \(reason)"
        case let .updateFailed(entity, id, reason):
            return "Update \(entity) \(id) failed: \(reason)"
        case let .deleteFailed(entity, id, reason):
            return "Delete \(entity) \(id) failed: \(reason)"
        }
    }

    public var userMessage: String {
        switch self {
        case let .notFound(entity, _):
            return "\(entity) not found."
        case .queryFailed:
            return "Failed to fetch data. Please try again."
        case .insertFailed:
            return "Failed to save data. Please try again."
        case .updateFailed:
            return "Failed to update. Please try again."
        case .deleteFailed:
            return "Failed to delete. Please try again."
        }
    }

    public var isRetryable: Bool {
        true
    }
}

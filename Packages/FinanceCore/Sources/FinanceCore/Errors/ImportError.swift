//
//  ImportError.swift
//  FinanceCore
//
//  Created by Pratik Goel on 17/05/26.
//

import Foundation

public enum ImportError: FinanceError {
    case noFilesSelected
    case noTargetSelected
    case targetNotFound(UUID)
    case duplicateDetected(count: Int)
    case importFailed(reason: String)
    case rollbackFailed(reason: String)

    public var category: ErrorCategory {
        .importOperation
    }

    public var severity: ErrorSeverity {
        switch self {
        case .duplicateDetected:
            return .info
        case .noFilesSelected, .noTargetSelected:
            return .warning
        case .targetNotFound, .importFailed, .rollbackFailed:
            return .error
        }
    }

    public var technicalMessage: String {
        switch self {
        case .noFilesSelected:
            return "No files provided for import"
        case .noTargetSelected:
            return "No target ledger selected for import"
        case let .targetNotFound(id):
            return "Target ledger not found: \(id.uuidString)"
        case let .duplicateDetected(count):
            return "\(count) duplicate transactions detected via sourceFingerprint"
        case let .importFailed(reason):
            return "Import operation failed: \(reason)"
        case let .rollbackFailed(reason):
            return "Rollback failed: \(reason)"
        }
    }

    public var userMessage: String {
        switch self {
        case .noFilesSelected:
            return "Please select at least one file to import."
        case .noTargetSelected:
            return "Please select which account to import into."
        case let .targetNotFound(id):
            return "The selected account (\(id.uuidString)) no longer exists."
        case let .duplicateDetected(count):
            return "\(count) transaction(s) were already imported and skipped."
        case let .importFailed(reason):
            return "Import failed. \(reason)"
        case .rollbackFailed:
            return "Import failed and could not be rolled back. Contact support."
        }
    }

    public var isRetryable: Bool {
        switch self {
        case .noFilesSelected, .noTargetSelected, .targetNotFound, .duplicateDetected:
            return false
        case .importFailed, .rollbackFailed:
            return true
        }
    }
}

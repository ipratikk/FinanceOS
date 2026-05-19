//
//  FileAccessError.swift
//  FinanceCore
//
//  Created by Pratik Goel on 17/05/26.
//

import Foundation

public enum FileAccessError: FinanceError {
    case fileNotFound(path: String)
    case permissionDenied(path: String)
    case invalidPath(String)
    case readFailed(path: String, reason: String)

    public var category: ErrorCategory {
        .fileAccess
    }

    public var severity: ErrorSeverity {
        .error
    }

    public var technicalMessage: String {
        switch self {
        case let .fileNotFound(path):
            return "File not found: \(path)"
        case let .permissionDenied(path):
            return "Permission denied: \(path)"
        case let .invalidPath(path):
            return "Invalid file path: \(path)"
        case let .readFailed(path, reason):
            return "Failed to read \(path): \(reason)"
        }
    }

    public var userMessage: String {
        switch self {
        case let .fileNotFound(path):
            return "File not found: \(URL(fileURLWithPath: path).lastPathComponent)"
        case .permissionDenied:
            return "Permission denied. Check file permissions and try again."
        case .invalidPath:
            return "Invalid file path."
        case .readFailed:
            return "Unable to read file. The file may be in use or corrupted."
        }
    }

    public var isRetryable: Bool {
        true
    }
}

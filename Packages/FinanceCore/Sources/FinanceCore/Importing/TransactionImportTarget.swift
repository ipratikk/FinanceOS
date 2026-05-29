//
//  TransactionImportTarget.swift
//  FinanceCore
//
//  Created by Pratik Goel on 13/05/26.
//

import Foundation

/// Identifies the destination for an import batch.  Currently only ledger-scoped imports are
/// supported; additional cases (e.g. sub-account) should extend this enum rather than adding fields.
public enum TransactionImportTarget:
    Sendable,
    Equatable,
    Hashable {
    /// Import transactions into the ledger with the given ID.
    case ledger(UUID)
}

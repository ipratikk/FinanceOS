//
//  TransactionImportTarget.swift
//  FinanceCore
//
//  Created by Pratik Goel on 13/05/26.
//

import Foundation

public enum TransactionImportTarget:
    Sendable,
    Equatable,
    Hashable {
    case ledger(UUID)
}

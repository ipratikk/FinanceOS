//
//  ParsedTransaction.swift
//  FinanceCore
//
//  Created by Pratik Goel on 13/05/26.
//

import Foundation

public struct ParsedTransaction:
    Sendable,
    Equatable
{
    public let postedAt: Date
    public let description: String
    public let amountMinorUnits: Int64
    public let currencyCode: String
    public let sourceFingerprint: String?

    public init(
        postedAt: Date,
        description: String,
        amountMinorUnits: Int64,
        currencyCode: String,
        sourceFingerprint: String? = nil
    ) {
        self.postedAt = postedAt
        self.description = description
        self.amountMinorUnits = amountMinorUnits
        self.currencyCode = currencyCode
        self.sourceFingerprint = sourceFingerprint
    }
}

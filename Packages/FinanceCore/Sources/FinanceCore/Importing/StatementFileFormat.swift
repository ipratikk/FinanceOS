//
//  StatementFileFormat.swift
//  FinanceCore
//
//  Created by Pratik Goel on 13/05/26.
//

import Foundation

public enum StatementFileFormat:
    String,
    Sendable,
    CaseIterable
{
    case csv
    case xlsx
    case pdf
}

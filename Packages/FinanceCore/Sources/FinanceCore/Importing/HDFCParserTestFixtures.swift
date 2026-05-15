//
//  HDFCParserTestFixtures.swift
//  FinanceCore
//
//  Created by Pratik Goel on 15/05/26.
//

import Foundation

enum HDFCParserTestFixtures {
    static let singleLineDebitTransaction = """
    01/04/25  UPI-SHAKE SHEHNAZ              01/04/25          2500.00             0.00
    """

    static let singleLineCreditTransaction = """
    02/04/25  SALARY CREDIT FROM EMPLOYER    02/04/25             0.00        50000.00
    """

    static let multiLineTransaction = """
    03/04/25  AMAZON TRANSFER TO
    SAVINGS ACCOUNT VIA APP            03/04/25          1000.00             0.00
    """

    static let transactionWithSpecialCharacters = """
    05/04/25  CHQ#12345-JOHN DOE & CO       05/04/25         15000.00             0.00
    """

    static let minimalTransaction = """
    10/04/25  ATM WITHDRAWAL                10/04/25          5000.00             0.00
    """

    static let hdfsStatementHeader = """
    Date,Narration,Value Date,Debit Amount,Credit Amount,Chq/Ref Number,Closing Balance
    """

    static let completeStatement = """
    \(hdfsStatementHeader)
    \(singleLineDebitTransaction)
    \(singleLineCreditTransaction)
    \(multiLineTransaction)
    \(transactionWithSpecialCharacters)
    \(minimalTransaction)
    """
}

enum HDFCParserTestValidator {
    static func validateTransactionCount(_ transactions: [ParsedTransaction], expected: Int) -> Bool {
        transactions.count == expected
    }

    static func validateTransactionAmount(
        _ transaction: ParsedTransaction,
        expectedAmount: Int64,
        tolerance: Int64 = 0
    ) -> Bool {
        abs(transaction.amountMinorUnits - expectedAmount) <= tolerance
    }

    static func validateTransactionDescription(
        _ transaction: ParsedTransaction,
        expectedKeywords: [String]
    ) -> Bool {
        let lowerDescription = transaction.description.lowercased()
        return expectedKeywords.allSatisfy { lowerDescription.contains($0.lowercased()) }
    }

    static func validateTransactionDate(
        _ transaction: ParsedTransaction,
        expectedDateString: String
    ) -> Bool {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "dd/MM/yy"
        guard let expectedDate = formatter.date(from: expectedDateString) else { return false }

        let calendar = Calendar.current
        return calendar.isDate(transaction.postedAt, inSameDayAs: expectedDate)
    }
}

import Foundation
import OSLog

private let logger = Logger(subsystem: "com.pratik.FinanceOS", category: "Parsing")

/// Converts a `NormalizedRow` from an HDFC bank TXT statement into a `ParsedTransaction`.
///
/// Dates are parsed via `DateParser.parseHDFCBank` (supports `dd/MM/yy` and `dd/MM/yyyy`).
/// Credit column maps to positive inflow; debit column maps to a negative amount (money out).
public struct HDFCBankTXTNormalizer: Sendable, CSVRowNormalizer {
    public init() {}

    public func normalize(normalizedRow: NormalizedRow) throws -> ParsedTransaction? {
        guard let dateStr = normalizedRow[.date],
              let descStr = normalizedRow[.description]
        else {
            return nil
        }

        guard let date = DateParser.parseHDFCBank(dateStr) else {
            return nil
        }

        let creditStr = normalizedRow[.credit] ?? ""
        let debitStr = normalizedRow[.debit] ?? ""

        let creditMinorUnits = !creditStr.isEmpty ? (AmountParser.parseToInt64(creditStr) ?? 0) : 0
        let debitMinorUnits = !debitStr.isEmpty ? (AmountParser.parseToInt64(debitStr) ?? 0) : 0

        if debitMinorUnits != 0 || creditMinorUnits != 0 {
            logger
                .debug(
                    // swiftlint:disable:next line_length
                    "Parsed amounts: date=\(dateStr, privacy: .public) debit=\(debitStr, privacy: .public)→\(debitMinorUnits) credit=\(creditStr, privacy: .public)→\(creditMinorUnits)"
                )
        }

        guard creditMinorUnits != 0 || debitMinorUnits != 0 else {
            return nil
        }

        let amount = creditMinorUnits > 0 ? -creditMinorUnits : debitMinorUnits
        let description = descStr
            .components(separatedBy: .whitespaces)
            .filter { !$0.isEmpty }
            .joined(separator: " ")

        let fpDesc = description.components(separatedBy: .whitespaces).filter { !$0.isEmpty }.joined()
        let fingerprint = "\(dateStr)|\(fpDesc)|\(creditMinorUnits)|\(debitMinorUnits)"
        let closingBalance = normalizedRow[.balance].flatMap { AmountParser.parseToInt64($0) }

        return ParsedTransaction(
            postedAt: date,
            description: description,
            amountMinorUnits: amount,
            currencyCode: "INR",
            sourceFingerprint: fingerprint,
            closingBalanceMinorUnits: closingBalance
        )
    }
}

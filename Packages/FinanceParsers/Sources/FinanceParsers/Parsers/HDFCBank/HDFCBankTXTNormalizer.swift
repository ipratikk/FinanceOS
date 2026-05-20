import Foundation
import OSLog

private let logger = Logger(subsystem: "com.pratik.FinanceOS", category: "Parsing")

public struct HDFCBankTXTNormalizer: Sendable {
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
        let description = descStr.trimmingCharacters(in: .whitespaces)

        let fingerprint = "\(dateStr)|\(description)|\(creditMinorUnits)|\(debitMinorUnits)"

        return ParsedTransaction(
            postedAt: date,
            description: description,
            amountMinorUnits: amount,
            currencyCode: "INR",
            sourceFingerprint: fingerprint
        )
    }
}

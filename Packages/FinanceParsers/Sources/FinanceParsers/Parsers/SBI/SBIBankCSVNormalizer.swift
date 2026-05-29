import Foundation

public struct SBIBankCSVNormalizer: Sendable {
    public init() {}

    public func normalize(normalizedRow: NormalizedRow) throws -> ParsedTransaction? {
        guard let dateStr = normalizedRow[.date],
              let descStr = normalizedRow[.description]
        else {
            return nil
        }

        guard let date = DateParser.parseSBIBank(dateStr) else {
            return nil
        }

        let creditStr = normalizedRow[.credit] ?? ""
        let debitStr = normalizedRow[.debit] ?? ""

        let creditMinorUnits = !creditStr.isEmpty ? (AmountParser.parseToInt64(creditStr) ?? 0) : 0
        let debitMinorUnits = !debitStr.isEmpty ? (AmountParser.parseToInt64(debitStr) ?? 0) : 0

        guard creditMinorUnits != 0 || debitMinorUnits != 0 else {
            return nil
        }

        let amount = creditMinorUnits > 0 ? -creditMinorUnits : debitMinorUnits
        let description = descStr.trimmingCharacters(in: .whitespaces)

        let fingerprint = "\(dateStr)|\(description)|\(creditMinorUnits)|\(debitMinorUnits)"
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

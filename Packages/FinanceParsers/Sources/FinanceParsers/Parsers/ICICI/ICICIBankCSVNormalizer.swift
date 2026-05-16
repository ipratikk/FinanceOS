import Foundation

public struct ICICIBankCSVNormalizer: Sendable {
    public init() {}

    public func normalize(normalizedRow: NormalizedRow) throws -> ParsedTransaction? {
        guard let dateStr = normalizedRow[.date],
              let descStr = normalizedRow[.description] else {
            return nil
        }

        guard let date = DateParser.parseICICIBank(dateStr) else {
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

        return ParsedTransaction(
            postedAt: date,
            description: description,
            amountMinorUnits: amount,
            currencyCode: "INR",
            sourceFingerprint: fingerprint
        )
    }
}

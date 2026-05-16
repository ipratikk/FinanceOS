import Foundation

public struct AmexCardCSVNormalizer: Sendable {
    public init() {}

    public func normalize(normalizedRow: NormalizedRow) throws -> ParsedTransaction? {
        guard let dateStr = normalizedRow[.date],
              let descStr = normalizedRow[.description],
              let amountStr = normalizedRow[.amount] else {
            return nil
        }

        guard let date = DateParser.parseAmex(dateStr) else {
            return nil
        }

        guard let amountMinorUnits = AmountParser.parseToInt64(amountStr) else {
            return nil
        }

        let isDebit = amountMinorUnits > 0
        let amount = isDebit ? amountMinorUnits : -amountMinorUnits
        let description = descStr.trimmingCharacters(in: .whitespaces)

        let fingerprint = "\(dateStr)|\(description)|\(amountMinorUnits)"

        return ParsedTransaction(
            postedAt: date,
            description: description,
            amountMinorUnits: amount,
            currencyCode: "INR",
            sourceFingerprint: fingerprint
        )
    }
}

import Foundation

/// Converts a `NormalizedRow` from an Amex card CSV statement into a `ParsedTransaction`.
///
/// Date format parsed via `DateParser.parseAmex`. The single amount column carries the raw
/// signed value — positive means a charge (spend), negative means a credit/refund.
public struct AmexCardCSVNormalizer: Sendable, CSVRowNormalizer {
    public init() {}

    public func normalize(normalizedRow: NormalizedRow) throws -> ParsedTransaction? {
        guard let dateStr = normalizedRow[.date],
              let descStr = normalizedRow[.description],
              let amountStr = normalizedRow[.amount]
        else {
            return nil
        }

        guard let date = DateParser.parseAmex(dateStr) else {
            return nil
        }

        guard let amountMinorUnits = AmountParser.parseToInt64(amountStr) else {
            return nil
        }

        let amount = amountMinorUnits
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

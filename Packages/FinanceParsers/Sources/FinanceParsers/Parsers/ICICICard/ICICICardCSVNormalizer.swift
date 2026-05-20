import Foundation

public struct ICICICardCSVNormalizer: Sendable, CSVRowNormalizer {
    public init() {}

    public func normalize(normalizedRow: NormalizedRow) throws -> ParsedTransaction? {
        guard let dateStr = normalizedRow[.date],
              let descStr = normalizedRow[.description],
              let amountStr = normalizedRow[.amount]
        else {
            return nil
        }

        guard let date = DateParser.parseICICICard(dateStr) else {
            return nil
        }

        guard let amountMinorUnits = AmountParser.parseToInt64(amountStr) else {
            return nil
        }

        let sign = normalizedRow[.sign] ?? ""
        let isCredit = sign.uppercased() == "CR"
        let amount = isCredit ? -amountMinorUnits : amountMinorUnits
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

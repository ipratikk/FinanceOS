import Foundation

/// Converts a `NormalizedRow` from an HDFC card statement into a `ParsedTransaction`.
///
/// Date format parsed via `DateParser.parseHDFCCard` (typically `dd/MM/yyyy`).
/// The `.sign` column carries "CR" for payments/refunds, making those negative amounts.
public struct HDFCCardCSVNormalizer: Sendable, CSVRowNormalizer {
    public init() {}

    public func normalize(normalizedRow: NormalizedRow) throws -> ParsedTransaction? {
        guard let dateStr = normalizedRow[.date],
              let descStr = normalizedRow[.description],
              let amountStr = normalizedRow[.amount]
        else {
            return nil
        }

        guard let date = DateParser.parseHDFCCard(dateStr) else {
            return nil
        }

        guard let amountMinorUnits = AmountParser.parseToInt64(amountStr) else {
            return nil
        }

        let sign = normalizedRow[.sign] ?? ""
        let isCredit = sign.lowercased() == "cr"
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

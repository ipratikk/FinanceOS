import Foundation

/// Extracts metadata from Amex card CSV rows.
///
/// The Amex CSV export contains no metadata header block — only Date, Description, Amount columns.
/// All fields return `nil`; this extractor exists for interface consistency with other parsers.
public struct AmexCardMetadataExtractor: Sendable {
    public init() {}

    /// Always returns empty `StatementMetadata`; no metadata is available in the Amex CSV format.
    public func extract(from rows: [[String]]) -> StatementMetadata {
        // AMEX CSV format is minimal: just Date, Description, Amount columns
        // No metadata headers in the file, so return empty metadata
        return StatementMetadata(
            customerName: nil,
            accountNumber: nil,
            fullAccountNumber: nil,
            accountType: nil,
            cardType: nil,
            generatedAt: nil
        )
    }
}

import Foundation

public struct AmexCardMetadataExtractor: Sendable {
    public init() {}

    public func extract(from rows: [[String]]) -> StatementMetadata {
        // AMEX CSV format is minimal: just Date, Description, Amount columns
        // No metadata headers in the file, so return empty metadata
        return StatementMetadata(
            customerName: nil,
            accountNumber: nil,
            generatedAt: nil
        )
    }
}

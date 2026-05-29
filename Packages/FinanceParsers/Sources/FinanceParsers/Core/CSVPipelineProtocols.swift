import Foundation

/// Maps a CSV header row to an ordered list of `ColumnRole` values, and maps data rows
/// to `NormalizedRow` using those roles. Implementors must be deterministic and stateless.
protocol CSVRowMapper: Sendable {
    /// Inspects `headerRow` and returns one `ColumnRole` per column position.
    /// Throws `TransactionImportError.missingRequiredColumn` if a required header is absent.
    func map(headerRow: [String]) throws -> [ColumnRole]

    /// Zips `row` fields with `roles` and produces a keyed `NormalizedRow`.
    func mapRow(_ row: [String], using roles: [ColumnRole]) -> NormalizedRow
}

/// Converts a `NormalizedRow` (already role-keyed) into a `ParsedTransaction`,
/// applying institution-specific amount/date/sign logic. Returns `nil` to skip non-transaction rows.
protocol CSVRowNormalizer: Sendable {
    /// Returns `nil` for header continuations, summary rows, or rows that fail validation.
    func normalize(normalizedRow: NormalizedRow) throws -> ParsedTransaction?
}

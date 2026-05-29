import Foundation

/// Semantic role assigned to each column in a bank statement CSV during the Mapper stage.
/// The Normalizer stage reads values keyed by role rather than by column index,
/// making parsers resilient to column reordering across statement versions.
public enum ColumnRole: String, Codable, Sendable, Hashable {
    /// Transaction date column.
    case date
    /// Merchant or narration description column.
    case description
    /// Debit-only amount column (money out).
    case debit
    /// Credit-only amount column (money in).
    case credit
    /// Combined signed amount column used when a single column carries both debits and credits.
    case amount
    /// Running account balance column.
    case balance
    /// Bank reference or cheque number column.
    case reference
    /// Sign indicator column (e.g. `"Dr"` / `"Cr"`) used alongside a magnitude column.
    case sign
    /// Column that carries no useful data and should be skipped by the Normalizer.
    case ignored
}

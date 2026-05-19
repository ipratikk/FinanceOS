import Foundation

public enum ColumnRole: String, Codable, Sendable, Hashable {
    case date
    case description
    case debit
    case credit
    case amount
    case balance
    case reference
    case sign
    case ignored
}

import Foundation

protocol CSVRowMapper: Sendable {
    func map(headerRow: [String]) throws -> [ColumnRole]
    func mapRow(_ row: [String], using roles: [ColumnRole]) -> NormalizedRow
}

protocol CSVRowNormalizer: Sendable {
    func normalize(normalizedRow: NormalizedRow) throws -> ParsedTransaction?
}

import FinanceParsers

// Backward-compatibility re-exports so callers that import FinanceCore don't need to import FinanceParsers.
// Do not remove these aliases; they are public API consumed by FinanceUI and the app target.

/// Bank-specific parser protocol; each institution implements this to produce a `ParsedStatement`.
public typealias InstitutionStatementParser = FinanceParsers.InstitutionStatementParser
/// Central registry that maps (bank, format) pairs to the correct `InstitutionStatementParser`.
public typealias StatementParserRegistry = FinanceParsers.StatementParserRegistry
/// Describes the origin of a statement file (bank identity + format metadata).
public typealias StatementSource = FinanceParsers.StatementSource
/// Discriminates between supported statement origins (e.g. CSV, XLSX, TXT).
public typealias StatementSourceType = FinanceParsers.StatementSourceType

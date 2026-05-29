import FinanceParsers
import Foundation
import Observation

/// Observable state bag that tracks a single end-to-end import flow: file selection → parse → match → confirm → result.
/// Owned by the import ViewModel; reset between imports so no stale state leaks across sessions.
@Observable
@MainActor
public final class ImportSession {
    // MARK: - Parse phase

    /// The data source (bank/format) selected by the user before file picking.
    public var selectedSource: StatementSource?
    /// File URLs chosen by the user for this import batch.
    public var fileURLs: [URL] = []
    /// Raw parsed output from the parser layer, one per file.
    public var parsedStatements: [ParsedStatement] = []

    /// Preview phase — maps each statement's UUID to the ledger the user confirmed it belongs to.
    public var matchedLedgers: [UUID: Ledger] = [:]

    /// Target creation phase — holds transient form state while the user creates a new ledger mid-import.
    public var targetBeingCreated: TargetCreationState?

    // MARK: - Final import

    /// The resolved import target (existing or newly created ledger) chosen by the user.
    public var selectedTarget: TransactionImportTarget?
    /// Result populated after the pipeline commits transactions to the database.
    public var importResult: ImportResult?

    // MARK: - Error handling

    public var errorMessage: String?
    public var isLoading = false

    public init() {}

    /// Clears all state so this session object can be reused for the next import.
    public func reset() {
        selectedSource = nil
        fileURLs = []
        parsedStatements = []
        matchedLedgers = [:]
        targetBeingCreated = nil
        selectedTarget = nil
        importResult = nil
        errorMessage = nil
        isLoading = false
    }
}

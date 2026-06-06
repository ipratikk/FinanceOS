import FinanceCore
import FinanceParsers
import Foundation
import Observation

/// Observable state bag that tracks a single end-to-end import flow: file selection → parse → match → confirm → result.
/// Owned by the import ViewModel; reset between imports so no stale state leaks across sessions.
@Observable
@MainActor
final class ImportSession {
    // MARK: - Parse phase

    var selectedSource: StatementSource?
    var fileURLs: [URL] = []
    var parsedStatements: [ParsedStatement] = []

    /// Preview phase — maps each statement's UUID to the ledger the user confirmed it belongs to.
    var matchedLedgers: [UUID: Ledger] = [:]

    /// Target creation phase — holds transient form state while the user creates a new ledger mid-import.
    var targetBeingCreated: TargetCreationState?

    // MARK: - Final import

    var selectedTarget: TransactionImportTarget?
    var importResult: ImportResult?

    // MARK: - Error handling

    var errorMessage: String?
    var isLoading = false

    init() {}

    func reset() {
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

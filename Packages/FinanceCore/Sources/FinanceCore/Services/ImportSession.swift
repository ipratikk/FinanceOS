import FinanceParsers
import Foundation
import Observation

@Observable
@MainActor
public final class ImportSession {
    // Parse phase
    public var selectedSource: StatementSource?
    public var fileURLs: [URL] = []
    public var parsedStatements: [ParsedStatement] = []

    /// Preview phase
    public var matchedLedgers: [UUID: Ledger] = [:]

    /// Target creation phase
    public var targetBeingCreated: TargetCreationState?

    // Final import
    public var selectedTarget: TransactionImportTarget?
    public var importResult: ImportResult?

    // Error handling
    public var errorMessage: String?
    public var isLoading = false

    public init() {}

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

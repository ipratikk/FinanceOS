/// Outcome of a single import batch, surfaced to the UI after `TransactionImportPipeline.execute`.
/// Skipped rows are duplicates detected by the SQLITE_CONSTRAINT path or the in-batch fingerprint check.
public struct ImportResult: Sendable, Equatable {
    /// Number of rows successfully written to the database.
    public let inserted: Int
    /// Number of rows dropped because a matching fingerprint already existed.
    public let skipped: Int

    public init(inserted: Int, skipped: Int) {
        self.inserted = inserted
        self.skipped = skipped
    }
}

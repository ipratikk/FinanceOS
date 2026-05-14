public struct ImportResult: Sendable {
    public let inserted: Int
    public let skipped: Int

    public init(inserted: Int, skipped: Int) {
        self.inserted = inserted
        self.skipped = skipped
    }
}

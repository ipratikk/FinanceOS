public enum StatementSourceRegistry {
    /// Returns all fully supported statement sources (with at least one enabled format).
    public static var supportedSources: [(bankName: String, sourceType: StatementSourceType)] {
        StatementSource.allCases
            .filter { !$0.allowedFormats.isEmpty }
            .map { ($0.bankName, $0.sourceType) }
    }

    /// Returns all available statement sources including those with limited format support.
    public static var allSources: [StatementSource] {
        StatementSource.allCases
    }
}

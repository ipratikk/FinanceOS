import Foundation

/// Orchestrates deterministic description generation. Never invents data.
///
/// Priority:
///   1. `RawPatternParser` — structured opaque bank formats (remittance, GST,
///      interest, salary, rent) parsed deterministically from the raw string.
///   2. `FallbackGenerator` — the canonical merchant/person name is the description.
///
/// There is no generative-AI tier. Apple Intelligence was removed because it
/// hallucinated activity nouns ("grocery order", "shopping spree") from bare
/// counterparty names. Every description now derives only from verified signals.
public struct DescriptionGenerator: Sendable {
    private let fallback: FallbackGenerator
    private let rawPatternParser: RawPatternParser

    public init() {
        fallback = FallbackGenerator()
        rawPatternParser = RawPatternParser()
    }

    /// Generate a human-readable transaction description. Deterministic.
    /// Always returns a non-empty, non-nil string.
    public func generate(from context: DescriptionContext) async -> String {
        generateSync(from: context)
    }

    /// Synchronous deterministic generation: RawPatternParser → FallbackGenerator.
    public func generateSync(from context: DescriptionContext) -> String {
        if let parsed = rawPatternParser.parse(context.rawDescription, merchantName: context.merchantName) {
            return parsed
        }
        return fallback.generate(from: context)
    }
}

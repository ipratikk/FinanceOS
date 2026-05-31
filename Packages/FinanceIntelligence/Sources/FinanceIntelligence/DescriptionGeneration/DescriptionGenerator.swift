import Foundation

/// Orchestrates description generation: tries Apple Intelligence, falls back to templates.
///
/// Priority:
///   1. `AppleIntelligenceAdapter` — natural language via Foundation Models (OS 15+/18+)
///   2. `FallbackGenerator` — deterministic templates (always available)
///
/// The generator is the only entry point for description generation in the pipeline.
/// All callers receive a non-empty string.
public struct DescriptionGenerator: Sendable {
    private let aiAdapter: AppleIntelligenceAdapter
    private let fallback: FallbackGenerator

    public init() {
        aiAdapter = AppleIntelligenceAdapter()
        fallback = FallbackGenerator()
    }

    /// Generate a human-readable transaction description.
    /// Always returns a non-empty, non-nil string.
    public func generate(from context: DescriptionContext) async -> String {
        if let aiDescription = await aiAdapter.generate(from: context),
           !aiDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return aiDescription
        }
        return fallback.generate(from: context)
    }

    /// Synchronous fallback-only generation. Use when async context unavailable.
    public func generateSync(from context: DescriptionContext) -> String {
        fallback.generate(from: context)
    }
}

import Foundation

/// Orchestrates description generation with a three-tier priority chain.
///
/// Priority:
///   1. `MLXDescriptionGenerator` — on-device LLM (factually verified results only)
///   2. `AppleIntelligenceAdapter` — natural language via Foundation Models (OS 15+/18+)
///   3. `FallbackGenerator` — deterministic templates (always available)
///
/// The generator is the only entry point for description generation in the pipeline.
/// All callers receive a non-empty string.
public struct DescriptionGenerator: Sendable {
    private let mlxGenerator: MLXDescriptionGenerator
    private let aiAdapter: AppleIntelligenceAdapter
    private let fallback: FallbackGenerator

    public init() {
        mlxGenerator = MLXDescriptionGenerator()
        aiAdapter = AppleIntelligenceAdapter()
        fallback = FallbackGenerator()
    }

    /// Generate a human-readable description using the full MLX → AppleIntelligence → Fallback chain.
    /// Always returns a non-empty string. Factuality guard is built into MLXDescriptionGenerator.
    public func generate(mlxInput: MLXDescriptionInput, context: DescriptionContext) async -> String {
        let mlxResult = await mlxGenerator.generate(from: mlxInput)
        // Only short-circuit on a verified LLM result; template results fall through to AppleIntelligence.
        if mlxResult.isFactuallyVerified, mlxResult.source == .llm {
            return mlxResult.description
        }
        if let aiDescription = await aiAdapter.generate(from: context),
           !aiDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return aiDescription
        }
        return fallback.generate(from: context)
    }

    /// Generate a human-readable transaction description without MLX context.
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

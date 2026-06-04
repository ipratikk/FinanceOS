import Foundation

// MARK: - LLM Text Generator Protocol

/// Abstraction over any LLM backend for description enhancement.
public protocol LLMTextGenerator: Sendable {
    func generate(prompt: String) async throws -> String?
}

// MARK: - MLX Description Input

/// Richer input for MLX-powered description generation (superset of DescriptionContext).
public struct MLXDescriptionInput: Sendable {
    public let merchant: String
    public let categoryId: String
    public let amountMinorUnits: Int
    public let currencyCode: String
    public let date: Date
    public let narration: String
    public let isDebit: Bool

    public init(
        merchant: String, categoryId: String,
        amountMinorUnits: Int, currencyCode: String = "INR",
        date: Date, narration: String, isDebit: Bool = true
    ) {
        self.merchant = merchant
        self.categoryId = categoryId
        self.amountMinorUnits = amountMinorUnits
        self.currencyCode = currencyCode
        self.date = date
        self.narration = narration
        self.isDebit = isDebit
    }

    var amountFormatted: String {
        let major = amountMinorUnits / 100
        let minor = abs(amountMinorUnits % 100)
        return minor > 0 ? "\(major).\(String(format: "%02d", minor))" : "\(major)"
    }
}

// MARK: - Description Generation Result

public struct DescriptionGenerationResult: Sendable {
    public let input: MLXDescriptionInput
    public let description: String
    public let isFactuallyVerified: Bool
    public let source: DescriptionSource

    public enum DescriptionSource: Sendable {
        case template
        case llm
    }
}

// MARK: - MLXDescriptionGenerator

/// Generates human-readable transaction descriptions with factuality guard.
///
/// Strategy:
///   1. Template-based fast path (factuality = 1.0, always factually correct)
///   2. LLM enhancement via any LLMTextGenerator when available (if factuality guard passes)
///
/// Factuality guard: rejects LLM output where amount or merchant differs from input.
/// Accepts max 50 inputs per batch. Latency target <2s per batch.
public actor MLXDescriptionGenerator {
    public static let maxBatchSize = 50

    private let llmRuntime: (any LLMTextGenerator)?
    private let formatter: DateFormatter

    public init(llmRuntime: (any LLMTextGenerator)? = nil) {
        self.llmRuntime = llmRuntime
        let fmt = DateFormatter()
        fmt.dateFormat = "MMM d"
        formatter = fmt
    }

    // MARK: - Public API

    /// Generate a single description. Always returns a non-empty string.
    public func generate(from input: MLXDescriptionInput) async -> DescriptionGenerationResult {
        let templateDesc = templateDescription(for: input)

        guard let llm = llmRuntime else {
            return DescriptionGenerationResult(
                input: input, description: templateDesc, isFactuallyVerified: true, source: .template
            )
        }

        let prompt = buildPrompt(for: input, fallback: templateDesc)
        if let llmDesc = try? await llm.generate(prompt: prompt),
           let verified = verifiedDescription(llmDesc, input: input) {
            return DescriptionGenerationResult(
                input: input, description: verified, isFactuallyVerified: true, source: .llm
            )
        }

        return DescriptionGenerationResult(
            input: input, description: templateDesc, isFactuallyVerified: true, source: .template
        )
    }

    /// Generate descriptions for a batch (max 50). Concurrent, latency <2s.
    public func generateBatch(_ inputs: [MLXDescriptionInput]) async -> [DescriptionGenerationResult] {
        let batch = Array(inputs.prefix(Self.maxBatchSize))
        return await withTaskGroup(of: DescriptionGenerationResult.self) { group in
            for input in batch {
                group.addTask { await self.generate(from: input) }
            }
            var results: [DescriptionGenerationResult] = []
            for await result in group {
                results.append(result)
            }
            return results
        }
    }

    // MARK: - Template Generation (factuality = 1.0)

    func templateDescription(for input: MLXDescriptionInput) -> String {
        let dateStr = formatter.string(from: input.date)
        let amount = input.amountFormatted
        let category = input.categoryId.components(separatedBy: ".").first ?? input.categoryId

        if input.isDebit {
            return "You paid ₹\(amount) at \(input.merchant) on \(dateStr) for \(category)."
        } else {
            return "You received ₹\(amount) from \(input.merchant) on \(dateStr)."
        }
    }

    // MARK: - LLM Prompt + Factuality Guard

    private func buildPrompt(for input: MLXDescriptionInput, fallback: String) -> String {
        "Rewrite this transaction in natural English (max 20 words, keep all facts): \(fallback)"
    }

    func verifiedDescription(_ candidate: String, input: MLXDescriptionInput) -> String? {
        let amount = input.amountFormatted
        let merchantKey = input.merchant.lowercased().components(separatedBy: " ").first ?? ""

        let hasAmount = candidate.contains(amount) || candidate.contains(amount.components(separatedBy: ".")[0])
        let hasMerchant = candidate.lowercased().contains(merchantKey)

        guard hasAmount && hasMerchant else { return nil }
        let trimmed = candidate.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}

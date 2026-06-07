#if canImport(FoundationModels)
import FoundationModels
#endif
import Foundation

/// Apple Intelligence (Foundation Models) adapter for natural language description generation.
/// Gated behind `#available(macOS 26.0, *)` — compiles and degrades gracefully on older OS.
/// Falls back to `FallbackGenerator` when Foundation Models is unavailable or generation fails.
///
/// Apple Intelligence NEVER decides category, intent, or relationship.
/// It receives structured intelligence and converts it to natural language only.
public struct AppleIntelligenceAdapter: Sendable {
    private let fallback: FallbackGenerator

    public init() {
        fallback = FallbackGenerator()
    }

    /// Generate a natural language description.
    /// Returns `nil` when Foundation Models is unavailable — caller falls back to `FallbackGenerator`.
    public func generate(from context: DescriptionContext) async -> String? {
        if #available(macOS 26.0, iOS 26.0, *) {
            return await generateWithFoundationModels(context: context)
        }
        return nil
    }

    // MARK: - Private

    @available(macOS 26.0, iOS 26.0, *)
    private func generateWithFoundationModels(context: DescriptionContext) async -> String? {
        #if canImport(FoundationModels)
        let prompt = buildPrompt(context: context)
        do {
            let session = LanguageModelSession()
            let response = try await session.respond(to: prompt)
            let text = response.content.trimmingCharacters(in: .whitespacesAndNewlines)
            return validate(text, merchantName: context.merchantName)
        } catch {
            return nil
        }
        #else
        return nil
        #endif
    }

    @available(macOS 26.0, iOS 26.0, *)
    private func buildPrompt(context: DescriptionContext) -> String {
        let direction = context.isDebit ? "payment out" : "received"
        let recurringNote = context.isRecurring
            ? " (recurring \(context.recurringCadence?.rawValue ?? ""))"
            : ""
        let isExtended = shouldUseExtendedFormat(context: context)
        let wordCount = isExtended ? "10-12" : "5-6"
        let example = isExtended
            ? #"Example: "Monthly Netflix subscription renewed — ₹649 streaming plan""#
            : #"Example: "Grocery delivery via Blinkit""#

        return """
        Write a \(wordCount) word transaction description. No filler words. Factual only.
        Merchant: \(context.merchantName)
        Category: \(context.categoryId ?? "unknown")
        Direction: \(direction)\(recurringNote)
        \(example)
        Output ONLY the description, nothing else.
        """
    }

    private func shouldUseExtendedFormat(context: DescriptionContext) -> Bool {
        if context.categoryId == "income" && !context.isDebit { return true }
        if context.categoryId == "fees.interest" { return true }
        let lower = context.merchantName.lowercased()
        if lower.contains("usd") || lower.contains("inw") || lower.contains("forex") { return true }
        return false
    }

    private func validate(_ candidate: String, merchantName: String) -> String? {
        guard !candidate.isEmpty else { return nil }
        let words = candidate.split(separator: " ")
        guard words.count >= 3, words.count <= 20 else { return nil }
        let merchantFirst = merchantName.lowercased().split(separator: " ").first.map(String.init) ?? ""
        if !merchantFirst.isEmpty, merchantFirst.count > 2,
           !candidate.lowercased().contains(merchantFirst) {
            return nil
        }
        return candidate
    }
}

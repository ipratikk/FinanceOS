import Foundation

/// Apple Intelligence (Foundation Models) adapter for natural language description generation.
/// Gated behind `#available(macOS 15.0, iOS 18.0, *)` — compiles and degrades gracefully
/// on older OS. Falls back to `FallbackGenerator` when unavailable or when the model fails.
///
/// Apple Intelligence NEVER decides category, intent, or relationship.
/// It receives structured intelligence and converts it to natural language only.
public struct AppleIntelligenceAdapter: Sendable {
    private let fallback: FallbackGenerator

    public init() {
        fallback = FallbackGenerator()
    }

    /// Generate a natural language description.
    /// Returns `nil` when Apple Intelligence is unavailable — caller uses fallback.
    public func generate(from context: DescriptionContext) async -> String? {
        if #available(macOS 15.0, iOS 18.0, *) {
            return await generateWithFoundationModels(context: context)
        }
        return nil
    }

    // MARK: - Private

    @available(macOS 15.0, iOS 18.0, *)
    private func generateWithFoundationModels(context: DescriptionContext) async -> String? {
        // Foundation Models session would be constructed here.
        // The prompt is structured to give the model only linguistic freedom,
        // not intelligence decisions.
        //
        // Example prompt structure (not yet wired — requires entitlement + device):
        //   "Write a concise, natural English description for this bank transaction.
        //    Merchant: \(context.merchantName)
        //    Intent: \(context.intent.rawValue)
        //    Recurring: \(context.isRecurring ? "yes, \(context.recurringCadence?.rawValue ?? "")" : "no")
        //    Direction: \(context.isDebit ? "payment" : "receipt")
        //    Relationship: \(context.relationship?.rawValue ?? "none")
        //    Rules: ≤8 words, no amounts, no dates, no emojis."
        //
        // Foundation Models integration requires:
        //   1. com.apple.developer.foundation-models entitlement
        //   2. import FoundationModels (Xcode 16+)
        //   3. LanguageModelSession instantiation
        //
        // Until entitlement is provisioned, this returns nil → fallback fires.
        return nil
    }
}

import Foundation

/// Two-layer Jaccard-similarity kNN classifier for on-device transaction categorization.
///
/// Layer 1 (base) — read-only bundled seeds loaded from `BundledSeeds` at app launch.
/// Layer 2 (personal) — append-only user corrections that persist across app updates.
/// Inference merges both layers; personal examples are weighted 1.5× to let user ground truth win ties.
public actor LocalTransactionLearner {
    /// A single training example used by the kNN classifier.
    public struct LabeledExample: Codable, Sendable {
        /// Whitespace/punctuation-split tokens from the normalized description (length >= 2).
        public let tokens: [String]
        /// Taxonomy category ID this example belongs to.
        public let categoryId: String
        /// When the example was added (`.distantPast` for bundled seeds).
        public let addedAt: Date
        /// True when this example was created from a user correction rather than the seed bundle.
        public let isUserProvided: Bool
        /// App version string at the time the example was added.
        public let appVersion: String

        public init(
            tokens: [String],
            categoryId: String,
            addedAt: Date = Date(),
            isUserProvided: Bool,
            appVersion: String
        ) {
            self.tokens = tokens
            self.categoryId = categoryId
            self.addedAt = addedAt
            self.isUserProvided = isUserProvided
            self.appVersion = appVersion
        }

        public static var currentAppVersion: String {
            Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
        }
    }

    /// Layer 1: base examples from BundledSeeds — never written to by user corrections.
    /// Updated automatically when a new app version ships with an updated BundledSeeds.
    private let baseExamples: [LabeledExample]

    // Layer 2: user corrections — append-only, persists across app updates.
    private var personalExamples: [LabeledExample]
    private let personalStoreURL: URL

    private let k: Int
    private let minimumSimilarity: Double
    private let personalWeight: Double // multiplier for personal examples vs base

    public init(
        personalStoreURL: URL,
        k: Int = 7,
        minimumSimilarity: Double = 0.15,
        personalWeight: Double = 1.5
    ) {
        self.personalStoreURL = personalStoreURL
        self.k = k
        self.minimumSimilarity = minimumSimilarity
        self.personalWeight = personalWeight

        // Layer 1: always freshest bundled seeds (automatically updated with app)
        baseExamples = BundledSeeds.load()

        // Layer 2: user history persists across app updates
        personalExamples = Self.loadFromDisk(at: personalStoreURL)
    }

    // MARK: - Learning

    /// Add a user correction to the personal layer. Immediately available for inference.
    /// Does not touch the base layer.
    public func addExample(normalizedDescription: String, categoryId: String) throws {
        let tokens = Snapshot.tokenize(normalizedDescription)
        guard !tokens.isEmpty else { return }
        personalExamples.append(LabeledExample(
            tokens: tokens,
            categoryId: categoryId,
            isUserProvided: true,
            appVersion: LabeledExample.currentAppVersion
        ))
        try saveToDisk()
    }

    // MARK: - Snapshot (batch inference without actor contention)

    /// Returns a Sendable snapshot of both layers for concurrent batch inference.
    /// Callers run k-NN on the snapshot without holding the actor.
    public func snapshot() -> Snapshot {
        Snapshot(
            base: baseExamples, personal: personalExamples,
            k: k, minimumSimilarity: minimumSimilarity, personalWeight: personalWeight
        )
    }

    // MARK: - Inference (single, convenience — acquires actor for each call)

    /// Convenience single-transaction inference. Acquires the actor on each call — use `snapshot()` for batches.
    public func predict(normalizedDescription: String) -> (categoryId: String, confidence: Double)? {
        snapshot().predict(normalizedDescription: normalizedDescription)
    }

    // MARK: - Stats

    /// Number of examples in the read-only base layer (bundled seeds).
    public var baseExampleCount: Int {
        baseExamples.count
    }

    /// Number of examples in the personal layer (accumulated from user corrections).
    public var personalExampleCount: Int {
        personalExamples.count
    }

    /// Total number of examples across both layers.
    public var totalExampleCount: Int {
        baseExamples.count + personalExamples.count
    }
}

// MARK: - Snapshot

public extension LocalTransactionLearner {
    /// Sendable value-type snapshot of both example layers for lock-free batch inference.
    /// Obtain with a single `learner.snapshot()` actor hop, then call `predict` from any context.
    struct Snapshot: Sendable {
        let base: [LabeledExample]
        let personal: [LabeledExample]
        let k: Int
        let minimumSimilarity: Double
        let personalWeight: Double

        /// Runs k-NN inference over both layers and returns the winning category and confidence.
        /// Returns nil when no neighbors meet the `minimumSimilarity` threshold.
        public func predict(normalizedDescription: String) -> (categoryId: String, confidence: Double)? {
            let queryTokens = Set(Self.tokenize(normalizedDescription))
            guard !queryTokens.isEmpty else { return nil }
            let baseN = scoredNeighbors(from: base, query: queryTokens, weight: 1.0)
            let personalN = scoredNeighbors(from: personal, query: queryTokens, weight: personalWeight)
            let merged = (personalN + baseN).sorted(by: { $0.score > $1.score }).prefix(k)
            guard !merged.isEmpty else { return nil }
            return majorityVote(Array(merged))
        }

        // swiftlint:disable:next nesting
        private struct ScoredNeighbor { let score: Double; let categoryId: String }

        private func scoredNeighbors(
            from examples: [LabeledExample],
            query: Set<String>,
            weight: Double
        ) -> [ScoredNeighbor] {
            examples.compactMap { ex in
                let sim = jaccard(query, Set(ex.tokens))
                guard sim >= minimumSimilarity else { return nil }
                return ScoredNeighbor(score: sim * weight, categoryId: ex.categoryId)
            }
        }

        private func majorityVote(_ neighbors: [ScoredNeighbor]) -> (categoryId: String, confidence: Double)? {
            var votes: [String: Double] = [:]
            for n in neighbors {
                votes[n.categoryId, default: 0] += n.score
            }
            guard let winner = votes.max(by: { $0.value < $1.value }) else { return nil }
            let total = votes.values.reduce(0, +)
            return (winner.key, total > 0 ? min(winner.value / total, 0.95) : 0)
        }

        private func jaccard(_ a: Set<String>, _ b: Set<String>) -> Double {
            guard !a.isEmpty, !b.isEmpty else { return 0 }
            return Double(a.intersection(b).count) / Double(a.union(b).count)
        }

        static func tokenize(_ text: String) -> [String] {
            text.lowercased()
                .components(separatedBy: CharacterSet.alphanumerics.inverted)
                .filter { $0.count >= 2 }
        }
    }
}

// MARK: - Persistence (personal layer only)

private extension LocalTransactionLearner {
    func saveToDisk() throws {
        let data = try JSONEncoder().encode(personalExamples)
        try data.write(to: personalStoreURL, options: .atomic)
    }

    static func loadFromDisk(at url: URL) -> [LabeledExample] {
        guard let data = try? Data(contentsOf: url),
              let examples = try? JSONDecoder().decode([LabeledExample].self, from: data)
        else { return [] }
        return examples
    }
}

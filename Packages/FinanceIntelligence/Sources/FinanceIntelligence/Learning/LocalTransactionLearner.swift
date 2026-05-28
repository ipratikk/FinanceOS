import Foundation

// Two-layer nearest-neighbor classifier for on-device transaction categorization.
//
// Layer 1 — Base (read-only at runtime):
//   Loaded from BundledSeeds at app launch. Updated when user installs a new app version.
//   Provides general accuracy for all users on day 1.
//
// Layer 2 — Personal (append-only, persists across app updates):
//   Grows from user corrections. Never overwritten by app updates.
//   User corrections from v1.0 carry forward into v2.0, v3.0, etc.
//
// Inference: both layers are queried and their scores are merged.
// Personal examples outweigh base examples (1.5×) — user ground truth wins ties.
//
// "Merge" happens automatically at init — base layer always contains the latest bundled
// seeds (updated with each app release), personal layer always contains all user history.
public actor LocalTransactionLearner {
    public struct LabeledExample: Codable, Sendable {
        public let tokens: [String]
        public let categoryId: String
        public let addedAt: Date
        public let isUserProvided: Bool
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
        let tokens = Self.tokenize(normalizedDescription)
        guard !tokens.isEmpty else { return }
        personalExamples.append(LabeledExample(
            tokens: tokens,
            categoryId: categoryId,
            isUserProvided: true,
            appVersion: LabeledExample.currentAppVersion
        ))
        try saveToDisk()
    }

    // MARK: - Inference

    /// Merge both layers and return the best prediction.
    /// Returns nil when combined confidence is below threshold.
    public func predict(normalizedDescription: String) -> (categoryId: String, confidence: Double)? {
        let queryTokens = Set(Self.tokenize(normalizedDescription))
        guard !queryTokens.isEmpty else { return nil }

        let baseNeighbors = scoredNeighbors(from: baseExamples, query: queryTokens, weight: 1.0)
        let personalNeighbors = scoredNeighbors(from: personalExamples, query: queryTokens, weight: personalWeight)

        // Merge: personal neighbors go first (higher weight → naturally ranked higher)
        let merged = (personalNeighbors + baseNeighbors)
            .sorted { $0.score > $1.score }
            .prefix(k)

        guard !merged.isEmpty else { return nil }
        return majorityVote(Array(merged))
    }

    // MARK: - Stats

    public var baseExampleCount: Int {
        baseExamples.count
    }

    public var personalExampleCount: Int {
        personalExamples.count
    }

    public var totalExampleCount: Int {
        baseExamples.count + personalExamples.count
    }
}

// MARK: - k-NN

private extension LocalTransactionLearner {
    struct ScoredNeighbor {
        let score: Double // similarity × weight
        let categoryId: String
    }

    func scoredNeighbors(
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

    func majorityVote(_ neighbors: [ScoredNeighbor]) -> (categoryId: String, confidence: Double)? {
        var votes: [String: Double] = [:]
        for n in neighbors {
            votes[n.categoryId, default: 0] += n.score
        }
        guard let winner = votes.max(by: { $0.value < $1.value }) else { return nil }
        let total = votes.values.reduce(0, +)
        let confidence = total > 0 ? min(winner.value / total, 0.95) : 0
        return (winner.key, confidence)
    }

    func jaccard(_ a: Set<String>, _ b: Set<String>) -> Double {
        guard !a.isEmpty, !b.isEmpty else { return 0 }
        return Double(a.intersection(b).count) / Double(a.union(b).count)
    }

    static func tokenize(_ text: String) -> [String] {
        text.lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { $0.count >= 2 }
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

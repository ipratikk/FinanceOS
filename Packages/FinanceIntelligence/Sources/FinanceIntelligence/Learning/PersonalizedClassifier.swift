import CoreML
import Foundation

// MARK: - TrainValidationSplit

/// Disjoint train and validation subsets produced by `PersonalizedClassifier.stratifiedSplit`.
public struct TrainValidationSplit: Sendable {
    public let train: [(text: String, categoryId: String)]
    public let validation: [(text: String, categoryId: String)]
    /// Categories excluded from validation because they had fewer than the minimum examples for splitting.
    public let skippedCategories: Set<String>
}

// MARK: - ClassificationEvaluationResult

/// Rich evaluation result computed on a held-out validation set.
public struct ClassificationEvaluationResult: Codable, Sendable {
    public static let minimumValidationCount = 10

    public let exampleCount: Int
    public let validationCount: Int
    public let accuracy: Double
    public let precisionMacro: Double
    public let recallMacro: Double
    public let f1Macro: Double
    public let confusionMatrix: [String: [String: Int]]
    public let coverage: Double
    public let averageConfidence: Double?
    public let categoryDistribution: [String: Int]

    public var hasReliableMetrics: Bool {
        validationCount >= Self.minimumValidationCount
    }
}

// MARK: - PersonalizedClassifier

/// On-device kNN classifier backed by NarrationEmbedder v0.1 embeddings + ANNIndex.
///
/// Replaces TF-IDF bag-of-words with 128-dim sentence embeddings for improved
/// merchant and category matching after user corrections.
/// Falls through (returns nil) when: index is empty, model unavailable, or
/// best match similarity is below `embeddingConfidenceThreshold`.
actor PersonalizedClassifier {
    /// Minimum cosine similarity for an embedding match to be returned as a prediction.
    static let embeddingConfidenceThreshold: Float = 0.70

    private let annIndex: ANNIndex
    private let embeddingGenerator: EmbeddingGenerator

    // MARK: - Factory

    static func load(annIndex: ANNIndex, embeddingGenerator: EmbeddingGenerator) -> PersonalizedClassifier {
        PersonalizedClassifier(annIndex: annIndex, embeddingGenerator: embeddingGenerator)
    }

    private init(annIndex: ANNIndex, embeddingGenerator: EmbeddingGenerator) {
        self.annIndex = annIndex
        self.embeddingGenerator = embeddingGenerator
    }

    // MARK: - Prediction

    /// Returns the nearest-neighbor category for the given narration, or nil if no confident match.
    func predict(normalizedDescription: String) async -> (categoryId: String, confidence: Double)? {
        guard !normalizedDescription.isEmpty else { return nil }
        let indexCount = await annIndex.count
        guard indexCount > 0 else { return nil }
        guard let vector = try? await embeddingGenerator.embed(normalizedDescription) else { return nil }
        guard let top = try? await annIndex.nearest(to: vector, topK: 1).first else { return nil }
        guard top.similarity >= Self.embeddingConfidenceThreshold else { return nil }
        return (top.label, Double(top.similarity))
    }

    // MARK: - Learning

    /// Store a user correction as an embedding, immediately available for future lookups.
    func addExample(normalizedDescription: String, categoryId: String) async throws {
        guard let vector = try? await embeddingGenerator.embed(normalizedDescription) else { return }
        let embedding = StoredEmbedding(
            transactionId: UUID().uuidString,
            label: categoryId,
            vector: vector,
            modelVersion: "narration-embedder-v0.1"
        )
        try await annIndex.insert(embedding)
    }

    /// Batch-store corrections as embeddings.
    func trainBatch(_ examples: [(text: String, categoryId: String)]) async throws {
        for example in examples {
            try await addExample(normalizedDescription: example.text, categoryId: example.categoryId)
        }
    }
}

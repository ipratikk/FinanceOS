import Foundation
import NaturalLanguage

/// Generates fixed-dimension float vectors from text using on-device NLEmbedding.
/// Vectors enable fuzzy merchant matching and clustering without exact string comparison.
///
/// Strategy: average word-level embeddings for all tokens in the input string.
/// Output dimension: determined by the NLEmbedding model (typically 64 or 128).
/// @unchecked Sendable: NLEmbedding is thread-safe for concurrent reads.
public struct EmbeddingGenerator: @unchecked Sendable {
    /// Target vector dimension matching NarrationEmbedder v0.1 output.
    public static let dimension: Int = 128

    private let embedding: NLEmbedding?

    public init() {
        embedding = NLEmbedding.wordEmbedding(for: .english)
    }

    /// Generate an embedding vector for the given text. Returns nil when NLEmbedding unavailable.
    /// The vector is L2-normalized for cosine similarity via dot product.
    public func embed(_ text: String) -> [Float]? {
        guard let embedding else { return nil }
        let tokens = tokenize(text)
        guard !tokens.isEmpty else { return nil }

        var sum = [Double](repeating: 0, count: Self.dimension)
        var count = 0
        for token in tokens {
            if let vector = embedding.vector(for: token), vector.count == Self.dimension {
                for (idx, val) in vector.enumerated() {
                    sum[idx] += val
                }
                count += 1
            }
        }
        guard count > 0 else { return nil }
        let averaged = sum.map { Float($0 / Double(count)) }
        return l2Normalize(averaged)
    }

    // MARK: - Private

    private func tokenize(_ text: String) -> [String] {
        var tokens: [String] = []
        let tagger = NLTagger(tagSchemes: [.tokenType])
        tagger.string = text.lowercased()
        tagger.enumerateTags(in: text.startIndex ..< text.endIndex, unit: .word, scheme: .tokenType) { _, range in
            let token = String(text[range]).lowercased()
            if token.count >= 2 { tokens.append(token) }
            return true
        }
        return tokens
    }

    private func l2Normalize(_ vector: [Float]) -> [Float] {
        let norm = sqrt(vector.map { $0 * $0 }.reduce(0, +))
        guard norm > 0 else { return vector }
        return vector.map { $0 / norm }
    }
}

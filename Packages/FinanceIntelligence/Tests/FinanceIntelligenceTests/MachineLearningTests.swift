import Foundation
import Testing

@testable import FinanceIntelligence

@Suite("MachineLearning — embeddings, index, training export")
struct MachineLearningTests {
    // MARK: - EmbeddingIndex

    @Test("Upsert and nearest neighbor returns correct match")
    func embeddingIndexNearestNeighbor() {
        var index = EmbeddingIndex()
        let v1: [Float] = [1, 0, 0, 0]
        let v2: [Float] = [0, 1, 0, 0]
        let v3: [Float] = [0.9, 0.1, 0, 0]  // closest to v1

        index.upsert(entityId: "e1", label: "Blinkit", vector: v1)
        index.upsert(entityId: "e2", label: "Spotify", vector: v2)
        index.upsert(entityId: "e3", label: "Blinkit2", vector: v3)

        let results = index.nearest(to: v1, topK: 2)
        #expect(results.first?.entityId == "e1")
        #expect(results.first?.similarity ?? 0 > 0.9)
    }

    @Test("Remove entry removes it from nearest neighbor results")
    func embeddingIndexRemove() {
        var index = EmbeddingIndex()
        index.upsert(entityId: "e1", label: "A", vector: [1, 0])
        index.upsert(entityId: "e2", label: "B", vector: [0, 1])
        index.remove(entityId: "e1")
        #expect(index.count == 1)
        let results = index.nearest(to: [1, 0], topK: 5)
        #expect(results.allSatisfy { $0.entityId != "e1" })
    }

    @Test("Cosine similarity between identical vectors is 1.0")
    func cosineSimilarityIdentical() {
        let index = EmbeddingIndex()
        let v: [Float] = [0.6, 0.8, 0, 0]
        #expect(abs(index.similarity(a: v, b: v) - 1.0) < 0.001)
    }

    @Test("Cosine similarity between orthogonal vectors is 0.0")
    func cosineSimilarityOrthogonal() {
        let index = EmbeddingIndex()
        let a: [Float] = [1, 0]
        let b: [Float] = [0, 1]
        #expect(abs(index.similarity(a: a, b: b)) < 0.001)
    }

    @Test("Empty index returns no nearest neighbors")
    func emptyIndexReturnsEmpty() {
        let index = EmbeddingIndex()
        let results = index.nearest(to: [1, 0], topK: 5)
        #expect(results.isEmpty)
    }

    // MARK: - EmbeddingGenerator

    @Test("EmbeddingGenerator returns nil-or-valid (availability depends on OS)")
    func embeddingGeneratorNilOrValid() {
        let gen = EmbeddingGenerator()
        let result = gen.embed("blinkit grocery delivery")
        // Either nil (NLEmbedding unavailable in test env) or valid 64-dim vector
        if let vector = result {
            #expect(vector.count == EmbeddingGenerator.dimension)
            // L2-normalized → magnitude ≈ 1.0
            let magnitude = sqrt(vector.map { $0 * $0 }.reduce(0, +))
            #expect(abs(magnitude - 1.0) < 0.01)
        }
        // nil is acceptable — NLEmbedding may not load in test sandbox
    }

    @Test("Empty string returns nil embedding")
    func emptyStringNilEmbedding() {
        let gen = EmbeddingGenerator()
        #expect(gen.embed("") == nil)
    }

    // MARK: - TrainingDataExporter

    @Test("Export below threshold returns nil")
    func exportBelowThresholdNil() {
        let exporter = TrainingDataExporter()
        let corrections: [UserCorrection] = []
        #expect(exporter.exportCSV(from: corrections) == nil)
    }

    @Test("shouldExport respects count and interval thresholds")
    func shouldExportLogic() {
        let exporter = TrainingDataExporter()
        #expect(!exporter.shouldExport(correctionCount: 499, daysSinceLastExport: 30))
        #expect(!exporter.shouldExport(correctionCount: 500, daysSinceLastExport: 29))
        #expect(exporter.shouldExport(correctionCount: 500, daysSinceLastExport: 30))
        #expect(exporter.shouldExport(correctionCount: 1000, daysSinceLastExport: 45))
    }

    @Test("Unrestricted export produces valid CSV with header")
    func unrestrictedExportHasHeader() {
        let exporter = TrainingDataExporter()
        let corrections = makeSampleCorrections(count: 3)
        let csv = exporter.exportCSVUnrestricted(from: corrections)
        let lines = csv.split(separator: "\n", omittingEmptySubsequences: false)
        #expect(lines.first == "text,label")
        #expect(lines.count == 4)  // header + 3 rows
    }

    @Test("CSV escapes commas in merchant names")
    func csvEscapesCommas() {
        let exporter = TrainingDataExporter()
        let correction = UserCorrection(transactionId: UUID(),
            originalCategory: nil, correctedCategory: "dining",
            originalMerchant: nil, correctedMerchant: "Café, Corner",
            originalConfidence: nil, modelVersion: nil, isTrainingEligible: true
        )
        let csv = exporter.exportCSVUnrestricted(from: [correction])
        #expect(csv.contains("\"café, corner\""))
    }

    @Test("Sanitizer strips phone numbers and UPI handles")
    func sanitizerStripsPrivateData() {
        let exporter = TrainingDataExporter()
        // Merchant with UPI handle embedded — sanitized
        let correction = UserCorrection(
            transactionId: UUID(),
            originalCategory: nil, correctedCategory: "groceries",
            originalMerchant: nil, correctedMerchant: "Blinkit 9876543210 @airtel",
            originalConfidence: nil, modelVersion: nil, isTrainingEligible: true
        )
        let csv = exporter.exportCSVUnrestricted(from: [correction])
        #expect(!csv.contains("9876543210"))
        #expect(!csv.contains("@airtel"))
        #expect(csv.contains("blinkit"))
    }

    // MARK: - ModelManager

    @Test("ModelManager availability check does not crash")
    func modelManagerAvailability() async {
        let available = ModelManager.shared.isAvailable(.transactionCategoryClassifier)
        // May be true or false depending on bundle — just must not crash
        _ = available
    }

    // MARK: - Helpers

    private func makeSampleCorrections(count: Int) -> [UserCorrection] {
        (0..<count).map { i in
            UserCorrection(
                transactionId: UUID(),
                originalCategory: "transfers", correctedCategory: "groceries",
                originalMerchant: nil, correctedMerchant: "Merchant \(i)",
                originalConfidence: 0.5, modelVersion: "1.0", isTrainingEligible: true
            )
        }
    }
}

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
/// Never populated from training-set predictions — use `validateOnHeldOut` to produce this.
public struct ClassificationEvaluationResult: Codable, Sendable {
    public static let minimumValidationCount = 10

    /// Total labeled examples passed to the evaluation call.
    public let exampleCount: Int
    /// Number of examples reserved for validation (held-out).
    public let validationCount: Int
    /// Fraction of validation examples predicted correctly. Meaningful only when `hasReliableMetrics`.
    public let accuracy: Double
    /// Macro-averaged precision across all validation classes.
    public let precisionMacro: Double
    /// Macro-averaged recall across all validation classes.
    public let recallMacro: Double
    /// Macro-averaged F1 score across all validation classes.
    public let f1Macro: Double
    /// `trueLabel → predictedLabel → count` confusion matrix over the validation set.
    public let confusionMatrix: [String: [String: Int]]
    /// Fraction of unique categories that have at least one validation example.
    public let coverage: Double
    /// Mean model confidence across validation predictions, or nil when model is unavailable.
    public let averageConfidence: Double?
    /// Per-category example count across the full example set. Feeds `ModelRegistry` (INTEL-006).
    public let categoryDistribution: [String: Int]

    /// True when the validation set is large enough to produce reliable metrics.
    public var hasReliableMetrics: Bool {
        validationCount >= Self.minimumValidationCount
    }
}

// MARK: - PersonalizedClassifier

/// On-device personalizable kNN classifier backed by CoreML's MLUpdateTask.
///
/// Starts empty — no predictions until the user makes corrections.
/// Each correction adds a labeled example via MLUpdateTask, which updates
/// the kNN model file in the app's Documents directory.
///
/// Feature encoding: 200-dim binary bag-of-words over a bundled vocabulary.
/// Same tokenization as Python training pipeline.
actor PersonalizedClassifier {
    static let confidenceThreshold: Double = 0.7

    private var model: MLModel?
    private let vocabulary: [String]
    private let bundleModelURL: URL
    private let personalizedModelURL: URL

    // MARK: - Factory

    static func load(personalizedModelURL: URL) async -> PersonalizedClassifier? {
        guard
            let vocabURL = Bundle.module.url(forResource: "transaction_vocab", withExtension: "json"),
            let data = try? Data(contentsOf: vocabURL),
            let vocab = try? JSONDecoder().decode([String].self, from: data)
        else { return nil }
        guard let bundleURL = Bundle.module.url(forResource: "TransactionKNNClassifier", withExtension: "mlmodelc")
            ?? Bundle.module.url(forResource: "TransactionKNNClassifier", withExtension: "mlmodel")
        else { return nil }
        return await PersonalizedClassifier(
            vocabulary: vocab,
            bundleModelURL: bundleURL,
            personalizedModelURL: personalizedModelURL
        )
    }

    private init(vocabulary: [String], bundleModelURL: URL, personalizedModelURL: URL) async {
        self.vocabulary = vocabulary
        self.bundleModelURL = bundleModelURL
        self.personalizedModelURL = personalizedModelURL
        model = await Self.loadModel(personalizedURL: personalizedModelURL, bundleURL: bundleModelURL)
    }

    // MARK: - Prediction

    func predict(normalizedDescription: String) -> (categoryId: String, confidence: Double)? {
        guard let model else { return nil }
        let vector = encode(normalizedDescription)
        guard
            let provider = try? MLDictionaryFeatureProvider(dictionary: [
                "features": MLFeatureValue(multiArray: vector)
            ]),
            let output = try? model.prediction(from: provider),
            let label = output.featureValue(for: "label")?.stringValue
        else { return nil }
        let confidence = output.featureValue(for: "labelProbs")?
            .dictionaryValue.compactMapValues { $0.doubleValue }[label] ?? 0.5
        return (label, confidence)
    }

    // MARK: - Learning via MLUpdateTask

    func trainBatch(_ examples: [(text: String, categoryId: String)]) async throws {
        guard !examples.isEmpty else { return }
        let sourceURL: URL = FileManager.default.fileExists(atPath: personalizedModelURL.path)
            ? personalizedModelURL : bundleModelURL
        let compiledSourceURL: URL = if sourceURL.pathExtension == "mlmodelc" {
            sourceURL
        } else {
            try await MLModel.compileModel(at: sourceURL)
        }
        let batchInputs = try examples.map { example -> MLDictionaryFeatureProvider in
            let features = encode(example.text)
            return try MLDictionaryFeatureProvider(dictionary: [
                "features": MLFeatureValue(multiArray: features),
                "label": MLFeatureValue(string: example.categoryId)
            ])
        }
        let batch = MLArrayBatchProvider(array: batchInputs)
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString + ".mlmodelc")
        // Capture actor-isolated properties before entering the escaping completion handler.
        let savedModelURL = personalizedModelURL
        let savedBundleURL = bundleModelURL
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            do {
                let task = try MLUpdateTask(
                    forModelAt: compiledSourceURL,
                    trainingData: batch,
                    configuration: nil,
                    completionHandler: { context in
                        if let error = context.task.error {
                            continuation.resume(throwing: error); return
                        }
                        do {
                            try context.model.write(to: tempURL)
                            if FileManager.default.fileExists(atPath: savedModelURL.path) {
                                try FileManager.default.removeItem(at: savedModelURL)
                            }
                            try FileManager.default.moveItem(at: tempURL, to: savedModelURL)
                            continuation.resume()
                        } catch { continuation.resume(throwing: error) }
                    }
                )
                task.resume()
            } catch { continuation.resume(throwing: error) }
        }
        model = await Self.loadModel(personalizedURL: savedModelURL, bundleURL: savedBundleURL)
    }

    func addExample(normalizedDescription: String, categoryId: String) async throws {
        let sourceURL: URL = FileManager.default.fileExists(atPath: personalizedModelURL.path)
            ? personalizedModelURL : bundleModelURL
        let compiledSourceURL: URL = if sourceURL.pathExtension == "mlmodelc" {
            sourceURL
        } else {
            try await MLModel.compileModel(at: sourceURL)
        }
        let features = encode(normalizedDescription)
        let trainingInput = try MLDictionaryFeatureProvider(dictionary: [
            "features": MLFeatureValue(multiArray: features),
            "label": MLFeatureValue(string: categoryId)
        ])
        let batch = MLArrayBatchProvider(array: [trainingInput])
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString + ".mlmodelc")
        let savedModelURL = personalizedModelURL
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            do {
                let task = try MLUpdateTask(
                    forModelAt: compiledSourceURL,
                    trainingData: batch,
                    configuration: nil,
                    completionHandler: { context in
                        if let error = context.task.error {
                            continuation.resume(throwing: error); return
                        }
                        do {
                            try context.model.write(to: tempURL)
                            if FileManager.default.fileExists(atPath: savedModelURL.path) {
                                try FileManager.default.removeItem(at: savedModelURL)
                            }
                            try FileManager.default.moveItem(at: tempURL, to: savedModelURL)
                            continuation.resume()
                        } catch { continuation.resume(throwing: error) }
                    }
                )
                task.resume()
            } catch { continuation.resume(throwing: error) }
        }
        model = await Self.loadModel(personalizedURL: personalizedModelURL, bundleURL: bundleModelURL)
    }

    // MARK: - Feature Encoding

    func encode(_ text: String) -> MLMultiArray {
        let tokens = Set(
            text.lowercased()
                .components(separatedBy: CharacterSet.alphanumerics.inverted)
                .filter { $0.count >= 2 }
        )
        guard let array = try? MLMultiArray(shape: [NSNumber(value: vocabulary.count)], dataType: .float32) else {
            return MLMultiArray()
        }
        for (i, word) in vocabulary.enumerated() {
            array[i] = NSNumber(value: tokens.contains(word) ? 1.0 : 0.0)
        }
        return array
    }

    // MARK: - Model Loading

    static func loadModel(personalizedURL: URL, bundleURL: URL) async -> MLModel? {
        if FileManager.default.fileExists(atPath: personalizedURL.path) {
            return try? await MLModel.load(contentsOf: personalizedURL)
        }
        if bundleURL.pathExtension == "mlmodelc" {
            return try? await MLModel.load(contentsOf: bundleURL)
        }
        guard let compiled = try? await MLModel.compileModel(at: bundleURL) else { return nil }
        return try? await MLModel.load(contentsOf: compiled)
    }
}

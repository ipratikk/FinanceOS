import CoreML
import Foundation

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

    /// Loads the classifier, reading the vocabulary from the bundle and the model from `personalizedModelURL`.
    /// Returns nil when the bundle vocabulary or base model resource is missing.
    static func load(personalizedModelURL: URL) async -> PersonalizedClassifier? {
        guard
            let vocabURL = Bundle.module.url(forResource: "transaction_vocab", withExtension: "json"),
            let data = try? Data(contentsOf: vocabURL),
            let vocab = try? JSONDecoder().decode([String].self, from: data),
            let bundleURL = Bundle.module.url(forResource: "TransactionKNNClassifier", withExtension: "mlmodel")
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

    /// Encodes `normalizedDescription` as a binary bag-of-words and runs kNN inference.
    /// Returns nil when the model is not loaded or the output feature names are unexpected.
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

    /// Adds a labeled training example using `MLUpdateTask`, atomically replacing the persisted model.
    /// After the update task completes, reloads the in-memory model so the next `predict` call reflects the change.
    func addExample(normalizedDescription: String, categoryId: String) async throws {
        let sourceURL: URL = FileManager.default.fileExists(atPath: personalizedModelURL.path)
            ? personalizedModelURL : bundleModelURL

        let compiledSourceURL = try await MLModel.compileModel(at: sourceURL)

        let features = encode(normalizedDescription)
        let trainingInput = try MLDictionaryFeatureProvider(dictionary: [
            "features": MLFeatureValue(multiArray: features),
            "label": MLFeatureValue(string: categoryId)
        ])
        let batch = MLArrayBatchProvider(array: [trainingInput])

        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString + ".mlmodelc")

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            do {
                let task = try MLUpdateTask(
                    forModelAt: compiledSourceURL,
                    trainingData: batch,
                    configuration: nil,
                    completionHandler: { context in
                        if let error = context.task.error {
                            continuation.resume(throwing: error)
                            return
                        }
                        do {
                            try context.model.write(to: tempURL)
                            if FileManager.default.fileExists(atPath: self.personalizedModelURL.path) {
                                try FileManager.default.removeItem(at: self.personalizedModelURL)
                            }
                            try FileManager.default.moveItem(at: tempURL, to: self.personalizedModelURL)
                            continuation.resume()
                        } catch {
                            continuation.resume(throwing: error)
                        }
                    }
                )
                task.resume()
            } catch {
                continuation.resume(throwing: error)
            }
        }

        model = await Self.loadModel(personalizedURL: personalizedModelURL, bundleURL: bundleModelURL)
    }

    // MARK: - Feature Encoding

    /// Encodes `text` as a 200-dim binary bag-of-words `MLMultiArray` using the bundled vocabulary.
    /// Tokens not in the vocabulary are silently ignored.
    private func encode(_ text: String) -> MLMultiArray {
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

    private static func loadModel(personalizedURL: URL, bundleURL: URL) async -> MLModel? {
        if FileManager.default.fileExists(atPath: personalizedURL.path) {
            return try? await MLModel.load(contentsOf: personalizedURL)
        }
        guard let compiled = try? await MLModel.compileModel(at: bundleURL) else { return nil }
        return try? await MLModel.load(contentsOf: compiled)
    }
}

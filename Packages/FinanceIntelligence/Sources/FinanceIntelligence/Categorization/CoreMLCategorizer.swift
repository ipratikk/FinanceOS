import CoreML
import Foundation

/// Core ML inference wrapper. Loads TransactionCategoryClassifier.mlmodel from the module bundle.
/// Returns nil when the model is not present — service falls back to RuleBasedCategorizer.
///
/// Model: Trained tabular classifier (text + numeric features) via CreateML.
/// Inputs: description (String), amount_cents (Int64), is_income (Int64), is_debit (Int64)
/// Outputs: label (String), labelProbability (Dict[String: Double])
///
/// @unchecked Sendable: model is a let constant; MLModel.prediction(from:) is thread-safe for reads.
final class CoreMLCategorizer: @unchecked Sendable {
    static let descriptionFeatureKey = "description"
    static let amountFeatureKey = "amount_cents"
    static let incomeFeatureKey = "is_income"
    static let debitFeatureKey = "is_debit"

    private let model: MLModel?
    let modelVersion: String

    private init(model: MLModel?, modelVersion: String) {
        self.model = model
        self.modelVersion = modelVersion
    }

    static func load() async -> CoreMLCategorizer {
        let (model, version) = await loadModel()
        if model != nil {
            print("[CoreML] ✓ Model loaded (version: \(version))")
        } else {
            print("[CoreML] ✗ Model failed to load (version: \(version))")
        }
        return CoreMLCategorizer(model: model, modelVersion: version)
    }

    var isAvailable: Bool {
        model != nil
    }

    func predict(features: TransactionFeatures) -> CategoryPrediction? {
        guard let model else {
            print("[CoreML] Model not loaded")
            return nil
        }
        guard let provider = buildProvider(features: features) else {
            print("[CoreML] Failed to build feature provider")
            return nil
        }
        guard let output = try? model.prediction(from: provider) else {
            print("[CoreML] Prediction failed for: \(features.normalizedDescription)")
            return nil
        }
        let result = parseOutput(output)
        if result != nil {
            print("[CoreML] Predicted: \(result?.categoryId ?? "nil")")
        }
        return result
    }
}

// MARK: - Model Loading

private extension CoreMLCategorizer {
    static func loadModel() async -> (MLModel?, String) {
        guard let url = Bundle.module.url(
            forResource: "TransactionCategoryClassifier",
            withExtension: "mlmodel"
        ) else {
            return (nil, "none")
        }
        guard let model = try? await MLModel.load(contentsOf: url) else { return (nil, "load-failed") }
        let version = model.modelDescription.metadata[MLModelMetadataKey.versionString] as? String ?? "unknown"
        return (model, version)
    }
}

// MARK: - Inference

private extension CoreMLCategorizer {
    func buildProvider(features: TransactionFeatures) -> MLFeatureProvider? {
        let isIncome: Int64 = features.isDebit ? 0 : 1
        let isDebit: Int64 = features.isDebit ? 1 : 0
        let dict: [String: MLFeatureValue] = [
            Self.descriptionFeatureKey: MLFeatureValue(string: features.normalizedDescription),
            Self.amountFeatureKey: MLFeatureValue(int64: features.absoluteAmountMinorUnits),
            Self.incomeFeatureKey: MLFeatureValue(int64: isIncome),
            Self.debitFeatureKey: MLFeatureValue(int64: isDebit)
        ]
        return try? MLDictionaryFeatureProvider(dictionary: dict)
    }

    func parseOutput(_ output: MLFeatureProvider) -> CategoryPrediction? {
        guard let categoryLabel = output.featureValue(for: "label")?.stringValue else { return nil }
        let confidence = output.featureValue(for: "labelProbability")?.dictionaryValue
            .compactMapValues { $0.doubleValue }[categoryLabel] ?? 0.7
        return CategoryPrediction(
            categoryId: categoryLabel,
            subcategoryId: nil,
            displayName: categoryLabel,
            confidence: confidence,
            alternatives: [],
            source: .mlModel,
            modelVersion: modelVersion,
            taxonomyVersion: CategoryTaxonomy.current.version
        )
    }
}

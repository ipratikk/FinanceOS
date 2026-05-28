import CoreML
import Foundation

/// Core ML inference wrapper. Loads TransactionCategoryClassifier.mlmodel from the module bundle.
/// Returns nil when the model is not present — service falls back to RuleBasedCategorizer.
///
/// Model: Trained tabular classifier (text + numeric features) via CreateML.
/// Features: normalized_description, amount_cents, is_income, is_debit
///
/// @unchecked Sendable: model is a let constant; MLModel.prediction(from:) is thread-safe for reads.
final class CoreMLCategorizer: @unchecked Sendable {
    static let descriptionFeatureKey = "normalized_description"
    static let amountFeatureKey = "amount_cents"

    private let model: MLModel?
    let modelVersion: String

    private init(model: MLModel?, modelVersion: String) {
        self.model = model
        self.modelVersion = modelVersion
    }

    static func load() async -> CoreMLCategorizer {
        let (model, version) = await loadModel()
        return CoreMLCategorizer(model: model, modelVersion: version)
    }

    var isAvailable: Bool {
        model != nil
    }

    func predict(features: TransactionFeatures) -> CategoryPrediction? {
        guard let model else { return nil }
        guard let provider = buildProvider(features: features) else { return nil }
        guard let output = try? model.prediction(from: provider) else { return nil }
        return parseOutput(output)
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
        let dict: [String: MLFeatureValue] = [
            Self.descriptionFeatureKey: MLFeatureValue(string: features.normalizedDescription),
            Self.amountFeatureKey: MLFeatureValue(int64: features.absoluteAmountMinorUnits)
        ]
        return try? MLDictionaryFeatureProvider(dictionary: dict)
    }

    func parseOutput(_ output: MLFeatureProvider) -> CategoryPrediction? {
        guard let categoryLabel = output.featureValue(for: "category")?.stringValue else { return nil }
        let confidence = output.featureValue(for: "categoryProbability")?.dictionaryValue
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

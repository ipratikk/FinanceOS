import CoreML
import Foundation
import NaturalLanguage

/// NaturalLanguage model wrapper for the bundled CreateML text classifier.
/// Uses NLModel — the correct API for CreateML text classifiers. It handles
/// tokenization and preprocessing identically to the training pipeline,
/// unlike using MLModel directly which requires manual feature construction.
///
/// Load flow: .mlmodel (bundle) → MLModel.compileModel → NLModel(mlModel:)
/// Returns nil on any failure — service falls back to kNN → rules.
///
/// @unchecked Sendable: NLModel is internally thread-safe for concurrent reads.
final class CoreMLCategorizer: @unchecked Sendable {
    private let model: NLModel?
    let modelVersion: String

    private init(model: NLModel?, modelVersion: String) {
        self.model = model
        self.modelVersion = modelVersion
    }

    static func load() async -> CoreMLCategorizer {
        guard let url = Bundle.module.url(
            forResource: "TransactionCategoryClassifier",
            withExtension: "mlmodel"
        ) else {
            return CoreMLCategorizer(model: nil, modelVersion: "none")
        }
        do {
            let compiledUrl = try await MLModel.compileModel(at: url)
            let mlModel = try await MLModel.load(contentsOf: compiledUrl)
            let nlModel = try NLModel(mlModel: mlModel)
            let version = mlModel.modelDescription.metadata[MLModelMetadataKey.versionString] as? String
                ?? "text-classifier-v1"
            return CoreMLCategorizer(model: nlModel, modelVersion: version)
        } catch {
            return CoreMLCategorizer(model: nil, modelVersion: "load-failed")
        }
    }

    /// True when the bundled model loaded successfully and predictions are possible.
    var isAvailable: Bool {
        model != nil
    }

    /// Runs NLModel inference on `features.normalizedDescription` and returns a prediction.
    /// Returns nil when the model is unavailable or the NLModel returns no label.
    func predict(features: TransactionFeatures) -> CategoryPrediction? {
        guard let model else { return nil }
        let text = features.normalizedDescription
        guard let label = model.predictedLabel(for: text) else { return nil }
        let hypotheses = model.predictedLabelHypotheses(for: text, maximumCount: 5)
        let confidence = hypotheses[label] ?? 0.7
        return CategoryPrediction(
            categoryId: label,
            subcategoryId: nil,
            displayName: label,
            confidence: confidence,
            alternatives: [],
            source: .coreMLNLModel,
            modelVersion: modelVersion,
            taxonomyVersion: CategoryTaxonomy.current.version,
            confidenceKind: .uncalibratedScore
        )
    }
}

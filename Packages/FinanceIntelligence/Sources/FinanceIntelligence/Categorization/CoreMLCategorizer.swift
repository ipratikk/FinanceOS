import CoreML
import FinanceCore
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
/// KNOWN ISSUE: The bundled TransactionCategoryClassifier.mlmodel is a tabular
/// classifier (not a text classifier), which is incompatible with NLModel.
/// It will fail to load and isAvailable will be false until replaced with a
/// proper CreateML Text Classifier.
///
/// @unchecked Sendable: NLModel is internally thread-safe for concurrent reads.
final class CoreMLCategorizer: @unchecked Sendable {
    private let model: NLModel?
    let modelVersion: String
    let loadError: String?

    private init(model: NLModel?, modelVersion: String, loadError: String? = nil) {
        self.model = model
        self.modelVersion = modelVersion
        self.loadError = loadError
    }

    static func load() async -> CoreMLCategorizer {
        guard let url = Bundle.module.url(
            forResource: "TransactionCategoryClassifier",
            withExtension: "mlmodel"
        ) else {
            FinanceLogger.intelligence.warning("CoreMLCategorizer: TransactionCategoryClassifier.mlmodel not found in bundle")
            return CoreMLCategorizer(model: nil, modelVersion: "none", loadError: "bundle-missing")
        }
        do {
            let compiledUrl = try await MLModel.compileModel(at: url)
            let mlModel = try await MLModel.load(contentsOf: compiledUrl)
            let nlModel = try NLModel(mlModel: mlModel)
            let version = mlModel.modelDescription.metadata[MLModelMetadataKey.versionString] as? String
                ?? "text-classifier-v1"
            return CoreMLCategorizer(model: nlModel, modelVersion: version)
        } catch {
            FinanceLogger.intelligence.error("CoreMLCategorizer: model load failed — \(error). Inference falls back to kNN → rules.")
            return CoreMLCategorizer(model: nil, modelVersion: "load-failed", loadError: error.localizedDescription)
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

import CoreML
import FinanceCore
import Foundation
import NaturalLanguage

/// Wrapper for the bundled CoreML text classifier.
///
/// Supports two model architectures:
///
/// 1. **NLModel** (CreateML Text Classifier — preferred):
///    Load flow: .mlmodel → MLModel.compileModel → NLModel(mlModel:)
///    Inference: raw text string → predicted label. No preprocessing required.
///    Produced by: CreateML app → Text Classifier task.
///
/// 2. **MLModel bag-of-words** (sklearn pipeline via coremltools):
///    Load flow: .mlmodel → MLModel.compileModel → MLModel
///    Inference: tokenize text → dictionary<string,double> → predicted label.
///    Produced by: Scripts/train_category_classifier.py → Option A export.
///    Input feature name: "token_counts". Output feature name: "category".
///
/// Falls back to kNN → rules when both fail.
///
/// @unchecked Sendable: NLModel and MLModel are internally thread-safe for reads.
final class CoreMLCategorizer: @unchecked Sendable {
    private enum Backend {
        case nlModel(NLModel)
        case mlModel(MLModel)
    }

    private let backend: Backend?
    let modelVersion: String
    let loadError: String?

    private init(backend: Backend?, modelVersion: String, loadError: String? = nil) {
        self.backend = backend
        self.modelVersion = modelVersion
        self.loadError = loadError
    }

    static func load() async -> CoreMLCategorizer {
        // Xcode compiles .mlmodel → .mlmodelc at build time; try precompiled first.
        // swift build leaves .mlmodel uncompiled and requires runtime compilation.
        do {
            let mlModel: MLModel
            if let precompiled = Bundle.module.url(
                forResource: "TransactionCategoryClassifier", withExtension: "mlmodelc"
            ) {
                mlModel = try await MLModel.load(contentsOf: precompiled)
            } else if let source = Bundle.module.url(
                forResource: "TransactionCategoryClassifier", withExtension: "mlmodel"
            ) {
                let compiled = try await MLModel.compileModel(at: source)
                mlModel = try await MLModel.load(contentsOf: compiled)
            } else {
                FinanceLogger.intelligence.warning(
                    "CoreMLCategorizer: TransactionCategoryClassifier not found in bundle"
                )
                return CoreMLCategorizer(backend: nil, modelVersion: "none", loadError: "bundle-missing")
            }
            let version = mlModel.modelDescription.metadata[MLModelMetadataKey.versionString] as? String
            return detectBackend(mlModel: mlModel, version: version)
                ?? CoreMLCategorizer(backend: nil, modelVersion: "load-failed", loadError: "unsupported-model-type")
        } catch {
            FinanceLogger.intelligence
                .error("CoreMLCategorizer: model load failed. Inference falls back to kNN → rules.")
            return CoreMLCategorizer(
                backend: nil,
                modelVersion: "load-failed",
                loadError: error.localizedDescription
            )
        }
    }

    private static func detectBackend(mlModel: MLModel, version: String?) -> CoreMLCategorizer? {
        if let nlModel = try? NLModel(mlModel: mlModel) {
            FinanceLogger.intelligence.info("CoreMLCategorizer: loaded as NLModel")
            return CoreMLCategorizer(backend: .nlModel(nlModel), modelVersion: version ?? "nlmodel-v1")
        }
        let inputs = mlModel.modelDescription.inputDescriptionsByName
        let outputs = mlModel.modelDescription.outputDescriptionsByName
        guard inputs["token_counts"] != nil, outputs["category"] != nil else {
            FinanceLogger.intelligence.error(
                "CoreMLCategorizer: unsupported model type (not NLModel, not token_counts→category sklearn pipeline)"
            )
            return nil
        }
        FinanceLogger.intelligence.info("CoreMLCategorizer: loaded as MLModel (sklearn BoW pipeline)")
        return CoreMLCategorizer(backend: .mlModel(mlModel), modelVersion: version ?? "sklearn-bow-v1")
    }

    var isAvailable: Bool {
        backend != nil
    }

    func predict(features: TransactionFeatures) -> CategoryPrediction? {
        switch backend {
        case let .nlModel(nlModel):
            return predictNL(nlModel, features: features)
        case let .mlModel(mlModel):
            return predictBoW(mlModel, features: features)
        case nil:
            return nil
        }
    }

    // MARK: - NLModel inference

    private func predictNL(_ model: NLModel, features: TransactionFeatures) -> CategoryPrediction? {
        let text = mlText(from: features)
        guard let label = model.predictedLabel(for: text) else { return nil }
        let hypotheses = model.predictedLabelHypotheses(for: text, maximumCount: 5)
        let confidence = hypotheses[label] ?? 0.7
        return makePrediction(categoryId: label, confidence: confidence)
    }

    /// Extracts clean text for NLModel inference, matching Python training's clean_text().
    /// UPIDescriptionParser extracts the merchant name segment from raw Indian bank strings.
    /// Falls back to normalizedDescription for non-UPI/NEFT/IMPS formats.
    private func mlText(from features: TransactionFeatures) -> String {
        if let name = UPIDescriptionParser.merchantName(from: features.rawDescription) {
            return name.lowercased()
        }
        return features.normalizedDescription
    }

    // MARK: - MLModel bag-of-words inference

    private func predictBoW(_ model: MLModel, features: TransactionFeatures) -> CategoryPrediction? {
        let tokens = tokenize(features.normalizedDescription)
        guard !tokens.isEmpty else { return nil }
        do {
            let nsTokens = tokens.mapValues { $0 as NSNumber } as [AnyHashable: NSNumber]
            let featureValue = try MLFeatureValue(dictionary: nsTokens)
            let provider = try MLDictionaryFeatureProvider(dictionary: ["token_counts": featureValue])
            let output = try model.prediction(from: provider)
            guard let label = output.featureValue(for: "category")?.stringValue else { return nil }
            let confidence: Double = if let probs = output.featureValue(for: "categoryProbability")?
                .dictionaryValue as? [String: Double] {
                probs[label] ?? 0.7
            } else {
                0.7
            }
            return makePrediction(categoryId: label, confidence: confidence)
        } catch {
            return nil
        }
    }

    /// Unigram + bigram bag-of-words matching the Python training tokenizer.
    private func tokenize(_ text: String) -> [String: NSNumber] {
        let lower = text.lowercased()
        let tokens = lower.components(separatedBy: .init(charactersIn: " \t\n\r-_/.,;:!?()[]{}\"'"))
            .filter { $0.count >= 3 }
        var bow: [String: Int] = [:]
        for tok in tokens {
            bow[tok, default: 0] += 1
        }
        for (a, b) in zip(tokens, tokens.dropFirst()) {
            let bg = "\(a)_\(b)"
            bow[bg, default: 0] += 1
        }
        return bow.mapValues { NSNumber(value: Double($0)) }
    }

    // MARK: - Shared

    private func makePrediction(categoryId: String, confidence: Double) -> CategoryPrediction {
        CategoryPrediction(
            categoryId: categoryId,
            subcategoryId: nil,
            displayName: categoryId,
            confidence: confidence,
            alternatives: [],
            source: .coreMLNLModel,
            modelVersion: modelVersion,
            taxonomyVersion: CategoryTaxonomy.current.version,
            confidenceKind: .uncalibratedScore
        )
    }
}

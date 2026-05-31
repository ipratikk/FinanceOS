import CoreML
import Foundation
import NaturalLanguage

/// Manages CoreML model lifecycle: availability checks, lazy loading, version tracking.
/// All models optional — pipeline degrades gracefully when models are absent.
///
/// Models are loaded once and cached. Callers check `isAvailable` before using.
public actor ModelManager {
    public enum ModelName: String, Sendable {
        case transactionCategoryClassifier = "TransactionCategoryClassifier"
        case transactionKNN               = "TransactionKNNClassifier"
    }

    private var nlModels: [ModelName: NLModel] = [:]
    private var loadedVersions: [ModelName: String] = [:]

    public static let shared = ModelManager()

    private init() {}

    // MARK: - NLModel (text classifiers)

    /// Load and cache an NLModel from the module bundle. Returns nil if absent.
    public func nlModel(for name: ModelName) async -> NLModel? {
        if let cached = nlModels[name] { return cached }
        guard let url = Bundle.module.url(forResource: name.rawValue, withExtension: "mlmodel") else {
            return nil
        }
        do {
            let compiledUrl = try await MLModel.compileModel(at: url)
            let mlModel = try await MLModel.load(contentsOf: compiledUrl)
            let nlModel = try NLModel(mlModel: mlModel)
            nlModels[name] = nlModel
            loadedVersions[name] = mlModel.modelDescription
                .metadata[MLModelMetadataKey.versionString] as? String ?? "unknown"
            return nlModel
        } catch {
            return nil
        }
    }

    /// True when the model bundle resource exists (doesn't verify correctness).
    public nonisolated func isAvailable(_ name: ModelName) -> Bool {
        Bundle.module.url(forResource: name.rawValue, withExtension: "mlmodel") != nil
    }

    public func loadedVersion(for name: ModelName) -> String? {
        loadedVersions[name]
    }

    /// Evict cached model — forces reload on next access (e.g. after model update).
    public func evict(_ name: ModelName) {
        nlModels.removeValue(forKey: name)
        loadedVersions.removeValue(forKey: name)
    }
}

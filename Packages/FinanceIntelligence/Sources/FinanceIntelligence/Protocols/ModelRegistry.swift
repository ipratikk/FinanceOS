import Foundation
import CoreML

/// Registry for ML model artifacts. Single source of truth for model → artifact resolution.
/// No hardcoded model paths anywhere in production code.
public protocol ModelRegistry: Sendable {
    /// Load CoreML model artifact by logical name.
    func loadCoreML(_ name: ModelName) throws -> MLModel

    /// Get filesystem path to MLX model artifact directory.
    func mlxArtifactPath(for name: ModelName) throws -> URL

    /// Returns registered version metadata for a model.
    func version(for name: ModelName) -> ModelVersion?

    /// Validate artifact hash against registry entry.
    func validate(_ name: ModelName) throws

    /// All models with given status.
    func models(withStatus status: ModelStatus) -> [ModelRegistryEntry]
}

/// Logical model identifier (not filename).
public struct ModelName: RawRepresentable, Hashable, Sendable {
    public let rawValue: String

    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    // Predefined constants for all 11 models
    public static let merchant = ModelName("merchant_recognizer")
    public static let category = ModelName("category_classifier")
    public static let intent = ModelName("intent_classifier")
    public static let income = ModelName("income_classifier")
    public static let embedding = ModelName("embedding_encoder")
    public static let recurring = ModelName("recurring_detector")
    public static let anomaly = ModelName("anomaly_detector")
    public static let linkPredict = ModelName("link_predictor")
    public static let descriptionGen = ModelName("description_generator")
    public static let insightGen = ModelName("insight_generator")
}

/// Semantic version + training metadata for a model.
public struct ModelVersion: Sendable, Equatable {
    public let name: String
    public let version: String  // semver: "1.2.0"
    public let datasetVersion: String  // "2026-05-01" or empty if planned
    public let trainingDate: String  // ISO 8601 or empty if planned
    public let artifactHash: String  // SHA256 of artifact

    public init(
        name: String,
        version: String,
        datasetVersion: String,
        trainingDate: String,
        artifactHash: String
    ) {
        self.name = name
        self.version = version
        self.datasetVersion = datasetVersion
        self.trainingDate = trainingDate
        self.artifactHash = artifactHash
    }
}

/// Model lifecycle status.
public enum ModelStatus: String, Codable, Sendable {
    case active  // production model, loaded by default
    case shadow  // under evaluation, not served to users
    case deprecated  // old version, kept for reference
    case rollback  // previous active version, kept for fast revert
    case planned  // not yet trained
}

/// Single entry in model_registry.yaml.
public struct ModelRegistryEntry: Sendable {
    public let name: String
    public let version: String
    public let displayName: String
    public let artifactFilename: String
    public let artifactType: ArtifactType
    public let task: String
    public let inputType: String
    public let outputClasses: Int
    public let datasetVersion: String
    public let trainingDate: String
    public let evaluationDate: String
    public let metrics: [String: Double]
    public let artifactSHA256: String
    public let coremlSHA256: String
    public let trainingCommit: String
    public let datasetCommit: String
    public let minOSVersion: String
    public let memoryMB: Int
    public let status: ModelStatus
}

/// Artifact encoding format.
public enum ArtifactType: String, Codable, Sendable {
    case coreml
    case mlx
    case onnx
}

/// Registry errors.
public enum ModelRegistryError: Error, Sendable {
    case registryNotFound(String)
    case modelNotFound(String)
    case modelNotActive(String, ModelStatus)
    case artifactNotFound(String)
    case wrongArtifactType(String)
    case hashMismatch(String, expected: String, actual: String)
    case invalidYAML(String)
}

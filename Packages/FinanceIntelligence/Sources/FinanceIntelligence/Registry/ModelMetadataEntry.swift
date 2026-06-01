import Foundation

// MARK: - ModelMetadataEntry

/// A single training-run record written to `intelligence_model_metadata`.
/// One row per training run — never updated after insert.
public struct ModelMetadataEntry: Identifiable, Codable, Sendable {
    public let id: String
    public let modelName: String
    public let modelType: String
    public let modelVersion: String
    public let trainedAt: Date
    public let trainingExampleCount: Int
    public let validationExampleCount: Int?
    public let featureVersion: String?
    public let configVersion: String?
    public let accuracy: Double?
    public let precisionMacro: Double?
    public let recallMacro: Double?
    public let f1Macro: Double?
    public let brierScore: Double?
    public let expectedCalibrationError: Double?
    public let confusionMatrixJson: String?
    public let trainingDataHash: String?
    public let notes: String?

    public init(
        id: String = UUID().uuidString,
        modelName: String,
        modelType: String,
        modelVersion: String,
        trainedAt: Date = Date(),
        trainingExampleCount: Int,
        validationExampleCount: Int? = nil,
        featureVersion: String? = nil,
        configVersion: String? = nil,
        accuracy: Double? = nil,
        precisionMacro: Double? = nil,
        recallMacro: Double? = nil,
        f1Macro: Double? = nil,
        brierScore: Double? = nil,
        expectedCalibrationError: Double? = nil,
        confusionMatrixJson: String? = nil,
        trainingDataHash: String? = nil,
        notes: String? = nil
    ) {
        self.id = id
        self.modelName = modelName
        self.modelType = modelType
        self.modelVersion = modelVersion
        self.trainedAt = trainedAt
        self.trainingExampleCount = trainingExampleCount
        self.validationExampleCount = validationExampleCount
        self.featureVersion = featureVersion
        self.configVersion = configVersion
        self.accuracy = accuracy
        self.precisionMacro = precisionMacro
        self.recallMacro = recallMacro
        self.f1Macro = f1Macro
        self.brierScore = brierScore
        self.expectedCalibrationError = expectedCalibrationError
        self.confusionMatrixJson = confusionMatrixJson
        self.trainingDataHash = trainingDataHash
        self.notes = notes
    }

    /// Builds a kNN model version string: `personalized-knn-YYYYMMDD-HHmmss-<hashPrefix>`.
    public static func knnVersion(trainedAt date: Date, trainingDataHash: String?) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        let datePart = formatter.string(from: date)
        let hashPart = trainingDataHash.flatMap { $0.prefix(8) }.map { "-\($0)" } ?? ""
        return "personalized-knn-\(datePart)\(hashPart)"
    }

    /// Builds a CoreML model version string: `coreml-category-v<bundleVersion>`.
    public static func coreMLVersion(_ bundleVersion: String) -> String {
        "coreml-category-v\(bundleVersion)"
    }
}

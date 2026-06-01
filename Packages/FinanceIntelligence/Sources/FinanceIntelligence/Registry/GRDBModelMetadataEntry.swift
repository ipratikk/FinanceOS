import Foundation
import GRDB

/// GRDB record mapping `ModelMetadataEntry` to the `intelligence_model_metadata` table.
struct GRDBModelMetadataEntry: Codable, FetchableRecord, PersistableRecord {
    static let databaseTableName = "intelligence_model_metadata"

    var id: String
    var modelName: String
    var modelType: String
    var modelVersion: String
    var trainedAt: Date
    var trainingExampleCount: Int
    var validationExampleCount: Int?
    var featureVersion: String?
    var configVersion: String?
    var accuracy: Double?
    var precisionMacro: Double?
    var recallMacro: Double?
    var f1Macro: Double?
    var brierScore: Double?
    var expectedCalibrationError: Double?
    var confusionMatrixJson: String?
    var trainingDataHash: String?
    var notes: String?

    init(entry: ModelMetadataEntry) {
        id = entry.id
        modelName = entry.modelName
        modelType = entry.modelType
        modelVersion = entry.modelVersion
        trainedAt = entry.trainedAt
        trainingExampleCount = entry.trainingExampleCount
        validationExampleCount = entry.validationExampleCount
        featureVersion = entry.featureVersion
        configVersion = entry.configVersion
        accuracy = entry.accuracy
        precisionMacro = entry.precisionMacro
        recallMacro = entry.recallMacro
        f1Macro = entry.f1Macro
        brierScore = entry.brierScore
        expectedCalibrationError = entry.expectedCalibrationError
        confusionMatrixJson = entry.confusionMatrixJson
        trainingDataHash = entry.trainingDataHash
        notes = entry.notes
    }

    var asEntry: ModelMetadataEntry {
        ModelMetadataEntry(
            id: id,
            modelName: modelName,
            modelType: modelType,
            modelVersion: modelVersion,
            trainedAt: trainedAt,
            trainingExampleCount: trainingExampleCount,
            validationExampleCount: validationExampleCount,
            featureVersion: featureVersion,
            configVersion: configVersion,
            accuracy: accuracy,
            precisionMacro: precisionMacro,
            recallMacro: recallMacro,
            f1Macro: f1Macro,
            brierScore: brierScore,
            expectedCalibrationError: expectedCalibrationError,
            confusionMatrixJson: confusionMatrixJson,
            trainingDataHash: trainingDataHash,
            notes: notes
        )
    }
}

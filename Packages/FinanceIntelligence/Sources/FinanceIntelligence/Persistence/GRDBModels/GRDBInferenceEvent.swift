import Foundation
import GRDB

struct GRDBInferenceEvent: Codable, FetchableRecord, PersistableRecord {
    static let databaseTableName = "intelligence_inference_events"

    var id: String
    var transactionId: String?
    var stage: String
    var source: String
    var ruleId: String?
    var modelId: String?
    var modelVersion: String?
    var configVersion: String?
    var inputHash: String?
    var outputLabel: String?
    var outputIntent: String?
    var confidence: Double?
    var confidenceKind: String
    var debugJSON: String?
    var createdAt: Date

    init(event: IntelligenceEvent) {
        id = event.id.uuidString
        transactionId = event.transactionId
        stage = event.stage.rawValue
        source = event.source.rawValue
        ruleId = event.ruleId
        modelId = event.modelId
        modelVersion = event.modelVersion
        configVersion = event.configVersion
        inputHash = nil
        outputLabel = event.outputLabel
        outputIntent = event.outputIntent
        confidence = event.confidence
        confidenceKind = event.confidenceKind.rawValue
        debugJSON = event.debugJSON
        createdAt = event.createdAt
    }
}

import Foundation
import GRDB

/// Runtime configuration for `TransactionIntelligenceServiceImpl`.
/// Use `.default` for production; override URLs in tests or to point at a custom model location.
public struct IntelligenceServiceConfiguration: Sendable {
    /// On-disk path where `UserCorrectionStore` writes its JSON corrections file.
    public let correctionStoreURL: URL
    /// Legacy Swift kNN store — kept for migration only. New corrections go to personalizedKNNModelURL.
    public let personalLearnerURL: URL
    /// On-device updatable CoreML kNN model — grows with each user correction via MLUpdateTask.
    public let personalizedKNNModelURL: URL
    /// Taxonomy version used during categorization. Defaults to `CategoryTaxonomy.current`.
    public let taxonomy: CategoryTaxonomy

    /// When provided, person entities are persisted to SQLite via `GRDBIntelligencePersonRepository`.
    /// When nil, an in-memory `PersonEntityStore` is used (session-scoped, no persistence).
    public let databaseQueue: DatabaseQueue?

    /// Structured logger for intelligence inference events. Defaults to `NullIntelligenceLogger`.
    public let intelligenceLogger: any IntelligenceLogger

    public init(
        correctionStoreURL: URL,
        personalLearnerURL: URL,
        personalizedKNNModelURL: URL,
        taxonomy: CategoryTaxonomy = .current,
        databaseQueue: DatabaseQueue? = nil,
        intelligenceLogger: (any IntelligenceLogger)? = nil
    ) {
        self.correctionStoreURL = correctionStoreURL
        self.personalLearnerURL = personalLearnerURL
        self.personalizedKNNModelURL = personalizedKNNModelURL
        self.taxonomy = taxonomy
        self.databaseQueue = databaseQueue
        self.intelligenceLogger = intelligenceLogger ?? NullIntelligenceLogger()
    }

    /// Default configuration writing files to `~/Application Support/FinanceIntelligence/`.
    public static var `default`: IntelligenceServiceConfiguration {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
        let appSupport = base.first ?? FileManager.default.temporaryDirectory
        let dir = appSupport.appendingPathComponent("FinanceIntelligence", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return IntelligenceServiceConfiguration(
            correctionStoreURL: dir.appendingPathComponent("corrections.json"),
            personalLearnerURL: dir.appendingPathComponent("personal_examples.json"),
            personalizedKNNModelURL: dir.appendingPathComponent("PersonalizedKNN.mlmodelc")
        )
    }
}

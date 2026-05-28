import FinanceCore
import Foundation

public struct IntelligenceServiceConfiguration: Sendable {
    public let correctionStoreURL: URL
    public let taxonomy: CategoryTaxonomy

    public init(correctionStoreURL: URL, taxonomy: CategoryTaxonomy = .current) {
        self.correctionStoreURL = correctionStoreURL
        self.taxonomy = taxonomy
    }

    public static var `default`: IntelligenceServiceConfiguration {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("FinanceIntelligence", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return IntelligenceServiceConfiguration(
            correctionStoreURL: dir.appendingPathComponent("corrections.json")
        )
    }
}

public actor TransactionIntelligenceServiceImpl: TransactionIntelligenceService {
    private let normalizer: MerchantNormalizer
    private let ruleCategorizer: RuleBasedCategorizer
    private let coreMLCategorizer: CoreMLCategorizer?
    private let correctionStore: UserCorrectionStore
    private let insightEngine: SpendingInsightEngine
    private let extractor: TransactionFeatureExtractor
    private let taxonomy: CategoryTaxonomy

    public init(configuration: IntelligenceServiceConfiguration = .default) async {
        taxonomy = configuration.taxonomy
        correctionStore = UserCorrectionStore(storageURL: configuration.correctionStoreURL)
        normalizer = MerchantNormalizer()
        ruleCategorizer = RuleBasedCategorizer(taxonomy: configuration.taxonomy)
        coreMLCategorizer = await CoreMLCategorizer.load()
        insightEngine = SpendingInsightEngine()
        extractor = TransactionFeatureExtractor()
    }

    public func analyze(_ transaction: Transaction, context: IntelligenceContext) async throws -> AnalyzedTransaction {
        let features = extractor.extract(
            from: transaction,
            context: FeatureExtractionContext(ledgerKind: context.ledgerKind, institution: context.institution)
        )
        let merchant = normalizer.normalize(transaction.description)

        if let correction = await correctionStore.correction(for: transaction.id) {
            let prediction = correctionPrediction(correction, features: features)
            return AnalyzedTransaction(
                transaction: transaction, merchantCandidate: merchant,
                categoryPrediction: prediction, features: features, isUserCorrected: true
            )
        }

        let prediction = predictCategory(features: features, merchantCategoryId: merchant.categoryId)
        return AnalyzedTransaction(
            transaction: transaction, merchantCandidate: merchant,
            categoryPrediction: prediction, features: features, isUserCorrected: false
        )
    }

    public func analyzeBatch(
        _ transactions: [Transaction],
        context: IntelligenceContext
    ) async throws -> [AnalyzedTransaction] {
        try await withThrowingTaskGroup(of: AnalyzedTransaction.self) { group in
            for txn in transactions {
                group.addTask { try await self.analyze(txn, context: context) }
            }
            var results: [AnalyzedTransaction] = []
            for try await result in group {
                results.append(result)
            }
            return results
        }
    }

    public func generateInsights(for transactions: [Transaction]) async throws -> [TransactionInsight] {
        insightEngine.generate(for: transactions)
    }
}

// MARK: - Private Helpers

private extension TransactionIntelligenceServiceImpl {
    func predictCategory(features: TransactionFeatures, merchantCategoryId: String?) -> CategoryPrediction {
        if let coreML = coreMLCategorizer, coreML.isAvailable,
           let prediction = coreML.predict(features: features) {
            return prediction
        }
        if let categoryId = merchantCategoryId {
            let topLevel = categoryId.components(separatedBy: ".").first ?? categoryId
            let name = taxonomy.category(forId: topLevel)?.displayName ?? topLevel
            return CategoryPrediction(
                categoryId: topLevel,
                subcategoryId: categoryId,
                displayName: name,
                confidence: 0.88,
                alternatives: [],
                source: .alias,
                modelVersion: ModelMetadata.rulesBased.modelVersion,
                taxonomyVersion: taxonomy.version
            )
        }
        return ruleCategorizer.categorize(features)
    }

    func correctionPrediction(_ correction: UserCorrection, features: TransactionFeatures) -> CategoryPrediction {
        let name = taxonomy.category(forId: correction.correctedCategory)?.displayName
            ?? correction.correctedCategory
        return CategoryPrediction(
            categoryId: correction.correctedCategory,
            subcategoryId: nil,
            displayName: name,
            confidence: 1.0,
            alternatives: [],
            source: .userCorrection,
            modelVersion: ModelMetadata.rulesBased.modelVersion,
            taxonomyVersion: taxonomy.version
        )
    }
}

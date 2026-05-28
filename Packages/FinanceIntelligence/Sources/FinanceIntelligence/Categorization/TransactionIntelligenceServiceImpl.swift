import FinanceCore
import Foundation

public struct IntelligenceServiceConfiguration: Sendable {
    public let correctionStoreURL: URL
    /// Personal layer store — user corrections only, persists across app updates.
    /// Base layer comes from BundledSeeds (code), updated automatically with each app version.
    public let personalLearnerURL: URL
    public let taxonomy: CategoryTaxonomy

    public init(
        correctionStoreURL: URL,
        personalLearnerURL: URL,
        taxonomy: CategoryTaxonomy = .current
    ) {
        self.correctionStoreURL = correctionStoreURL
        self.personalLearnerURL = personalLearnerURL
        self.taxonomy = taxonomy
    }

    public static var `default`: IntelligenceServiceConfiguration {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
        let appSupport = base.first ?? FileManager.default.temporaryDirectory
        let dir = appSupport.appendingPathComponent("FinanceIntelligence", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return IntelligenceServiceConfiguration(
            correctionStoreURL: dir.appendingPathComponent("corrections.json"),
            personalLearnerURL: dir.appendingPathComponent("personal_examples.json")
        )
    }
}

public actor TransactionIntelligenceServiceImpl: TransactionIntelligenceService {
    private let normalizer: MerchantNormalizer
    private let ruleCategorizer: RuleBasedCategorizer
    private let coreMLCategorizer: CoreMLCategorizer?
    private let correctionStore: UserCorrectionStore
    private let learner: LocalTransactionLearner
    private let insightEngine: SpendingInsightEngine
    private let extractor: TransactionFeatureExtractor
    private let taxonomy: CategoryTaxonomy

    public init(configuration: IntelligenceServiceConfiguration = .default) async {
        taxonomy = configuration.taxonomy
        correctionStore = UserCorrectionStore(storageURL: configuration.correctionStoreURL)
        learner = LocalTransactionLearner(personalStoreURL: configuration.personalLearnerURL)
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

        let prediction = await predictCategory(features: features, merchantCategoryId: merchant.categoryId)
        return AnalyzedTransaction(
            transaction: transaction, merchantCandidate: merchant,
            categoryPrediction: prediction, features: features, isUserCorrected: false
        )
    }

    public func analyzeBatch(
        _ transactions: [Transaction],
        context: IntelligenceContext
    ) async throws -> [AnalyzedTransaction] {
        guard !transactions.isEmpty else { return [] }

        // Pre-fetch shared state — 2 actor hops total regardless of batch size.
        // Tasks then run fully in parallel with no further actor contention.
        let learnerSnap = await learner.snapshot()
        let allCorrections = await correctionStore.allCorrections()

        let norm = normalizer
        let ext = extractor
        let rules = ruleCategorizer
        let coreML = coreMLCategorizer
        let tax = taxonomy

        // Serial loop: no actor contention (snapshot used), no Swift 6 Sendable issues.
        // k-NN is CPU-bound — parallelism over an actor was never beneficial.
        var results = [AnalyzedTransaction]()
        results.reserveCapacity(transactions.count)
        let ctx = FeatureExtractionContext(ledgerKind: context.ledgerKind, institution: context.institution)

        for txn in transactions {
            let features = ext.extract(from: txn, context: ctx)
            let merchant = norm.normalize(txn.description)

            if let correction = allCorrections[txn.id] {
                let name = tax.category(forId: correction.correctedCategory)?.displayName
                    ?? correction.correctedCategory
                let prediction = CategoryPrediction(
                    categoryId: correction.correctedCategory, subcategoryId: nil,
                    displayName: name, confidence: 1.0, alternatives: [],
                    source: .userCorrection, modelVersion: "user-correction",
                    taxonomyVersion: tax.version
                )
                results.append(AnalyzedTransaction(
                    transaction: txn, merchantCandidate: merchant,
                    categoryPrediction: prediction, features: features, isUserCorrected: true
                ))
                continue
            }

            let prediction = Self.buildPrediction(
                features: features, merchant: merchant,
                learnerSnap: learnerSnap, coreML: coreML,
                rules: rules, taxonomy: tax
            )
            results.append(AnalyzedTransaction(
                transaction: txn, merchantCandidate: merchant,
                categoryPrediction: prediction, features: features, isUserCorrected: false
            ))
        }
        return results
    }

    public func generateInsights(for transactions: [Transaction]) async throws -> [TransactionInsight] {
        insightEngine.generate(for: transactions)
    }

    public func learn(
        transaction: Transaction,
        correctedCategoryId: String,
        correctedMerchant: String?,
        previousPrediction: CategoryPrediction?
    ) async throws {
        // 1. Persist for audit trail + future batch retraining
        let input = CorrectionInput(
            transactionId: transaction.id,
            originalCategory: previousPrediction?.categoryId,
            correctedCategory: correctedCategoryId,
            originalMerchant: transaction.merchantName,
            correctedMerchant: correctedMerchant,
            originalConfidence: previousPrediction?.confidence,
            modelVersion: previousPrediction?.modelVersion
        )
        try await correctionStore.record(input)

        // 2. Add to personal layer for immediate improvement (base layer untouched)
        let normalized = MerchantTextCleaner().normalizedForMatching(transaction.description)
        try await learner.addExample(
            normalizedDescription: normalized,
            categoryId: correctedCategoryId
        )

        // 3. Also learn the canonical merchant name if provided
        if let merchant = correctedMerchant, !merchant.isEmpty {
            try await learner.addExample(
                normalizedDescription: merchant.lowercased(),
                categoryId: correctedCategoryId
            )
        }
    }
}

// MARK: - Static Prediction (no actor needed — called from concurrent tasks)

extension TransactionIntelligenceServiceImpl {
    // swiftlint:disable:next function_parameter_count
    static func buildPrediction(
        features: TransactionFeatures,
        merchant: MerchantCandidate,
        learnerSnap: LocalTransactionLearner.Snapshot,
        coreML: CoreMLCategorizer?,
        rules: RuleBasedCategorizer,
        taxonomy: CategoryTaxonomy
    ) -> CategoryPrediction {
        if let local = learnerSnap.predict(normalizedDescription: features.normalizedDescription),
           local.confidence >= 0.6 {
            let topLevel = local.categoryId.components(separatedBy: ".").first ?? local.categoryId
            let name = taxonomy.category(forId: topLevel)?.displayName ?? topLevel
            return CategoryPrediction(
                categoryId: topLevel, subcategoryId: nil, displayName: name,
                confidence: local.confidence, alternatives: [], source: .mlModel,
                modelVersion: "on-device-knn", taxonomyVersion: taxonomy.version
            )
        }
        if let coreML, coreML.isAvailable, let pred = coreML.predict(features: features) { return pred }
        if let categoryId = merchant.categoryId {
            let topLevel = categoryId.components(separatedBy: ".").first ?? categoryId
            let name = taxonomy.category(forId: topLevel)?.displayName ?? topLevel
            return CategoryPrediction(
                categoryId: topLevel, subcategoryId: categoryId, displayName: name,
                confidence: 0.88, alternatives: [], source: .alias,
                modelVersion: ModelMetadata.rulesBased.modelVersion, taxonomyVersion: taxonomy.version
            )
        }
        return rules.categorize(features)
    }
}

// MARK: - Private Helpers

private extension TransactionIntelligenceServiceImpl {
    func predictCategory(
        features: TransactionFeatures,
        merchantCategoryId: String?
    ) async -> CategoryPrediction {
        // Priority 1: on-device learned model (trained from this user's corrections)
        if let local = await learner.predict(normalizedDescription: features.normalizedDescription),
           local.confidence >= 0.6 {
            let topLevel = local.categoryId.components(separatedBy: ".").first ?? local.categoryId
            let name = taxonomy.category(forId: topLevel)?.displayName ?? topLevel
            return CategoryPrediction(
                categoryId: topLevel,
                subcategoryId: nil,
                displayName: name,
                confidence: local.confidence,
                alternatives: [],
                source: .mlModel,
                modelVersion: "on-device-knn",
                taxonomyVersion: taxonomy.version
            )
        }

        // Priority 2: bundled Core ML model (if trained and deployed)
        if let coreML = coreMLCategorizer, coreML.isAvailable,
           let prediction = coreML.predict(features: features) {
            return prediction
        }

        // Priority 3: alias-derived category from merchant normalization
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

        // Priority 4: deterministic rules
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
            modelVersion: "user-correction",
            taxonomyVersion: taxonomy.version
        )
    }
}

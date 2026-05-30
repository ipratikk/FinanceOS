import FinanceCore
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

    public init(
        correctionStoreURL: URL,
        personalLearnerURL: URL,
        personalizedKNNModelURL: URL,
        taxonomy: CategoryTaxonomy = .current,
        databaseQueue: DatabaseQueue? = nil
    ) {
        self.correctionStoreURL = correctionStoreURL
        self.personalLearnerURL = personalLearnerURL
        self.personalizedKNNModelURL = personalizedKNNModelURL
        self.taxonomy = taxonomy
        self.databaseQueue = databaseQueue
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

/// Concrete implementation of `TransactionIntelligenceService`.
/// Prediction priority (highest to lowest):
///   1. Stored user correction
///   2. RuleEngine high-confidence hit (≥0.90) — also always provides intent
///   3. On-device CoreML kNN (personalized via MLUpdateTask)
///   4. Legacy Swift kNN (LocalTransactionLearner)
///   5. Bundled NLModel text classifier
///   6. Alias table lookup
///   7. RuleEngine fallback (deterministic keyword rules)
public actor TransactionIntelligenceServiceImpl: TransactionIntelligenceService {
    private let normalizer: MerchantNormalizer
    private let ruleCategorizer: RuleBasedCategorizer
    private let ruleEngine: RuleEngine
    private let personResolver: PersonResolver
    private let personRepository: any IntelligencePersonRepository
    private let coreMLCategorizer: CoreMLCategorizer?
    /// CoreML kNN classifier updated on-device via MLUpdateTask on each user correction.
    private let personalizedClassifier: PersonalizedClassifier?
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
        ruleEngine = RuleEngine(taxonomy: configuration.taxonomy)
        personResolver = PersonResolver()
        if let queue = configuration.databaseQueue {
            personRepository = GRDBIntelligencePersonRepository(dbQueue: queue)
        } else {
            personRepository = PersonEntityStore()
        }
        coreMLCategorizer = await CoreMLCategorizer.load()
        personalizedClassifier = await PersonalizedClassifier.load(
            personalizedModelURL: configuration.personalizedKNNModelURL
        )
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
        // Capture PersonalizedClassifier for batch use — predict() is actor-isolated
        // but safe to call from a serial loop (no concurrent actor contention here).
        let personalized = personalizedClassifier

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

            let prediction = await Self.buildPrediction(
                features: features, merchant: merchant,
                personalized: personalized, learnerSnap: learnerSnap,
                coreML: coreML, rules: rules, taxonomy: tax
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

    public func analyzeEnriched(
        _ transaction: Transaction,
        context: IntelligenceContext
    ) async throws -> EnrichedTransaction {
        let ctx = FeatureExtractionContext(ledgerKind: context.ledgerKind, institution: context.institution)
        let features = extractor.extract(from: transaction, context: ctx)
        let merchant = normalizer.normalize(transaction.description)
        let ruleResult = ruleEngine.evaluate(features)

        let categoryPrediction: CategoryPrediction
        let isUserCorrected: Bool

        if let correction = await correctionStore.correction(for: transaction.id) {
            categoryPrediction = correctionPrediction(correction, features: features)
            isUserCorrected = true
        } else if let ruleCat = ruleResult.categoryPrediction, ruleCat.confidence >= 0.90 {
            categoryPrediction = ruleCat
            isUserCorrected = false
        } else {
            categoryPrediction = await predictCategory(
                features: features,
                merchantCategoryId: merchant.categoryId
            )
            isUserCorrected = false
        }

        let resolvedEntities = await resolveEntities(
            description: transaction.description,
            date: transaction.postedAt
        )

        return EnrichedTransaction(
            transaction: transaction,
            merchantCandidate: merchant,
            categoryPrediction: categoryPrediction,
            intentPrediction: ruleResult.intentPrediction,
            features: features,
            isUserCorrected: isUserCorrected,
            pipelineVersion: "1.0",
            resolvedEntities: resolvedEntities
        )
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

        // 2. Add to on-device CoreML kNN via MLUpdateTask (primary personalization layer)
        let normalized = MerchantTextCleaner().normalizedForMatching(transaction.description)
        try await personalizedClassifier?.addExample(
            normalizedDescription: normalized,
            categoryId: correctedCategoryId
        )

        // 3. Also update legacy Swift kNN (fallback when PersonalizedClassifier unavailable)
        try await learner.addExample(
            normalizedDescription: normalized,
            categoryId: correctedCategoryId
        )
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
    // Stateless prediction helper for batch processing; no actor isolation needed (all inputs are value types).
    // swiftlint:disable:next function_parameter_count
    static func buildPrediction(
        features: TransactionFeatures,
        merchant: MerchantCandidate,
        personalized: PersonalizedClassifier?,
        learnerSnap: LocalTransactionLearner.Snapshot,
        coreML: CoreMLCategorizer?,
        rules: RuleBasedCategorizer,
        taxonomy: CategoryTaxonomy
    ) async -> CategoryPrediction {
        // Priority 1: on-device CoreML kNN (user corrections via MLUpdateTask)
        if let personalized,
           let knn = await personalized.predict(normalizedDescription: features.normalizedDescription),
           knn.confidence >= PersonalizedClassifier.confidenceThreshold {
            let name = taxonomy.category(forId: knn.categoryId)?.displayName ?? knn.categoryId
            return CategoryPrediction(
                categoryId: knn.categoryId, subcategoryId: nil, displayName: name,
                confidence: knn.confidence, alternatives: [], source: .mlModel,
                modelVersion: "personalized-knn", taxonomyVersion: taxonomy.version
            )
        }
        // Priority 2: legacy Swift kNN (fallback)
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
        // Priority 3: bundled NLModel text classifier
        if let coreML, coreML.isAvailable, let pred = coreML.predict(features: features) { return pred }
        // Priority 4: alias table
        if let categoryId = merchant.categoryId {
            let topLevel = categoryId.components(separatedBy: ".").first ?? categoryId
            let name = taxonomy.category(forId: topLevel)?.displayName ?? topLevel
            return CategoryPrediction(
                categoryId: topLevel, subcategoryId: categoryId, displayName: name,
                confidence: 0.88, alternatives: [], source: .alias,
                modelVersion: ModelMetadata.rulesBased.modelVersion, taxonomyVersion: taxonomy.version
            )
        }
        // Priority 5: deterministic rules
        return rules.categorize(features)
    }
}

// MARK: - Private Helpers

private extension TransactionIntelligenceServiceImpl {
    func predictCategory(
        features: TransactionFeatures,
        merchantCategoryId: String?
    ) async -> CategoryPrediction {
        // Priority 1: on-device CoreML kNN (user corrections via MLUpdateTask)
        if let personalized = personalizedClassifier,
           let knn = await personalized.predict(normalizedDescription: features.normalizedDescription),
           knn.confidence >= PersonalizedClassifier.confidenceThreshold {
            let name = taxonomy.category(forId: knn.categoryId)?.displayName ?? knn.categoryId
            return CategoryPrediction(
                categoryId: knn.categoryId, subcategoryId: nil, displayName: name,
                confidence: knn.confidence, alternatives: [], source: .mlModel,
                modelVersion: "personalized-knn", taxonomyVersion: taxonomy.version
            )
        }

        // Priority 2: legacy Swift kNN
        if let local = await learner.predict(normalizedDescription: features.normalizedDescription),
           local.confidence >= 0.6 {
            let topLevel = local.categoryId.components(separatedBy: ".").first ?? local.categoryId
            let name = taxonomy.category(forId: topLevel)?.displayName ?? topLevel
            return CategoryPrediction(
                categoryId: topLevel, subcategoryId: nil, displayName: name,
                confidence: local.confidence, alternatives: [], source: .mlModel,
                modelVersion: "on-device-knn", taxonomyVersion: taxonomy.version
            )
        }

        // Priority 3: bundled NLModel text classifier
        if let coreML = coreMLCategorizer, coreML.isAvailable,
           let prediction = coreML.predict(features: features) {
            return prediction
        }

        // Priority 4: alias table
        if let categoryId = merchantCategoryId {
            let topLevel = categoryId.components(separatedBy: ".").first ?? categoryId
            let name = taxonomy.category(forId: topLevel)?.displayName ?? topLevel
            return CategoryPrediction(
                categoryId: topLevel, subcategoryId: categoryId, displayName: name,
                confidence: 0.88, alternatives: [], source: .alias,
                modelVersion: ModelMetadata.rulesBased.modelVersion, taxonomyVersion: taxonomy.version
            )
        }

        // Priority 5: deterministic rules
        return ruleCategorizer.categorize(features)
    }

    func resolveEntities(description: String, date: Date) async -> ResolvedEntities? {
        guard let personResult = personResolver.resolve(description),
              personResult.confidence >= 0.70 else { return nil }
        do {
            let person = try await personRepository.findOrCreate(
                name: personResult.name,
                upiHandle: personResult.upiHandle,
                date: date
            )
            return ResolvedEntities(merchantId: nil, personId: person.id)
        } catch {
            return nil
        }
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

import FinanceCore
import Foundation
import GRDB
import NaturalLanguage

// swiftlint:disable type_body_length
/// Concrete implementation of `TransactionIntelligenceService`.
/// Prediction priority (highest to lowest):
///   1. Stored user correction
///   2. RuleEngine high-confidence hit (≥0.90) — also always provides intent
///   3. On-device CoreML kNN (personalized via MLUpdateTask)
///   4. Bundled NLModel text classifier
///   5. Alias table lookup
///   6. RuleEngine fallback (deterministic keyword rules)
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
    private let insightEngine: SpendingInsightEngine
    private let extractor: TransactionFeatureExtractor
    private let taxonomy: CategoryTaxonomy
    private let descriptionGenerator: DescriptionGenerator
    /// Background pipeline: graph, recurring, relationships. Nil when no databaseQueue provided.
    private let postProcessingPipeline: PostProcessingPipeline?
    private let intelligenceLogger: any IntelligenceLogger
    private let modelRegistry: ModelRegistry
    private let intelligenceConfig: IntelligenceConfig
    private let feedbackStore: any FeedbackStore

    public init(configuration: IntelligenceServiceConfiguration = .default) async {
        taxonomy = configuration.taxonomy
        correctionStore = UserCorrectionStore(storageURL: configuration.correctionStoreURL)
        normalizer = MerchantNormalizer()
        ruleCategorizer = RuleBasedCategorizer(taxonomy: configuration.taxonomy)
        ruleEngine = RuleEngine(taxonomy: configuration.taxonomy)
        personResolver = PersonResolver()
        if let queue = configuration.databaseQueue {
            personRepository = GRDBIntelligencePersonRepository(
                dbQueue: queue,
                feedbackStore: configuration.feedbackStore
            )
        } else {
            personRepository = PersonEntityStore()
        }
        let loadedCoreML = await CoreMLCategorizer.load()
        coreMLCategorizer = loadedCoreML
        personalizedClassifier = await PersonalizedClassifier.load(
            personalizedModelURL: configuration.personalizedKNNModelURL
        )
        intelligenceConfig = configuration.intelligenceConfig

        // Register bundled model provenance on first startup.
        // Inserts once; subsequent runs find an existing entry and skip.
        let registry = configuration.modelRegistry
        if await registry.currentVersion(for: "TransactionCategoryClassifier") == nil {
            let trainedAt = ISO8601DateFormatter().date(from: "2026-05-28T13:32:40Z") ?? Date()
            let notes = loadedCoreML.isAvailable
                ? "Bundled text classifier. Loaded successfully."
                // swiftlint:disable:next line_length
                : "Tabular classifier incompatible with NLModel API — load failed (\(loadedCoreML.loadError ?? "unknown")). Labels: fees, groceries, income, insurance, subscriptions, transfers (6 only). Replace with CreateML Text Classifier. Contains PII in model weights."
            await registry.register(ModelMetadataEntry(
                modelName: "TransactionCategoryClassifier",
                modelType: loadedCoreML.isAvailable ? "nlModelTextClassifier" : "tabularClassifier",
                modelVersion: loadedCoreML.modelVersion,
                trainedAt: trainedAt,
                trainingExampleCount: 0,
                notes: notes
            ))
        }
        insightEngine = SpendingInsightEngine(config: intelligenceConfig.insight)
        extractor = TransactionFeatureExtractor()
        descriptionGenerator = DescriptionGenerator()

        if let queue = configuration.databaseQueue {
            let graphRepo = GRDBGraphRepository(dbWriter: queue, graphConfig: intelligenceConfig.graph)
            let graphStore = await GraphStore(repository: graphRepo)
            let recurringRepo = GRDBRecurringPatternRepository(dbWriter: queue)
            let relationshipRepo = GRDBRelationshipRepository(dbWriter: queue)
            postProcessingPipeline = PostProcessingPipeline(
                graphStore: graphStore,
                recurringRepo: recurringRepo,
                relationshipRepo: relationshipRepo,
                intelligenceConfig: intelligenceConfig
            )
        } else {
            postProcessingPipeline = nil
        }
        intelligenceLogger = configuration.intelligenceLogger
        modelRegistry = configuration.modelRegistry
        feedbackStore = configuration.feedbackStore
    }

    public func analyze(_ transaction: Transaction, context: IntelligenceContext) async throws -> AnalyzedTransaction {
        let features = extractor.extract(
            from: transaction,
            context: FeatureExtractionContext(ledgerKind: context.ledgerKind, institution: context.institution)
        )
        let merchant = normalizer.normalize(transaction.description)

        if let correction = await correctionStore.correction(for: transaction.id) {
            let prediction = correctionPrediction(correction, features: features)
            await intelligenceLogger.record(IntelligenceEvent(
                transactionId: transaction.id.uuidString,
                stage: .finalCategorization, source: .userCorrection,
                modelVersion: prediction.modelVersion, outputLabel: prediction.categoryId,
                confidence: prediction.confidence, confidenceKind: .deterministic
            ))
            return AnalyzedTransaction(
                transaction: transaction, merchantCandidate: merchant,
                categoryPrediction: prediction, features: features, isUserCorrected: true
            )
        }

        let prediction = await predictCategory(features: features, merchantCategoryId: merchant.categoryId)
        await intelligenceLogger.record(IntelligenceEvent(
            transactionId: transaction.id.uuidString,
            stage: .finalCategorization, source: prediction.source,
            modelVersion: prediction.modelVersion, outputLabel: prediction.categoryId,
            confidence: prediction.confidence, confidenceKind: prediction.confidenceKind
        ))
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

        // Pre-fetch shared state — single actor hop regardless of batch size.
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
                    taxonomyVersion: tax.version, confidenceKind: .deterministic
                )
                results.append(AnalyzedTransaction(
                    transaction: txn, merchantCandidate: merchant,
                    categoryPrediction: prediction, features: features, isUserCorrected: true
                ))
                continue
            }

            let prediction = await Self.buildPrediction(
                features: features, merchant: merchant,
                personalized: personalized,
                coreML: coreML, rules: rules, taxonomy: tax,
                knnThreshold: intelligenceConfig.classification.knnConfidenceThreshold,
                configVersion: intelligenceConfig.version
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
        } else if let ruleCat = ruleResult.categoryPrediction,
                  ruleCat.confidence >= intelligenceConfig.classification.ruleConfidenceThreshold {
            // Only let high-confidence structural rules (salary, ATM, SGST, SIP, billpay)
            // override ML. Keyword-category rules are pruned; trained kNN handles those.
            categoryPrediction = ruleCat
            isUserCorrected = false
        } else {
            // kNN (PersonalizedClassifier) fires here at 0.7+ threshold — now trained on
            // full transaction corpus, so it handles merchant categories ML was missing.
            categoryPrediction = await predictCategory(
                features: features,
                merchantCategoryId: merchant.categoryId
            )
            isUserCorrected = false
        }

        await intelligenceLogger.record(IntelligenceEvent(
            transactionId: transaction.id.uuidString,
            stage: .finalCategorization, source: categoryPrediction.source,
            modelVersion: categoryPrediction.modelVersion, outputLabel: categoryPrediction.categoryId,
            outputIntent: ruleResult.intentPrediction.intent.rawValue,
            confidence: categoryPrediction.confidence, confidenceKind: categoryPrediction.confidenceKind
        ))
        let resolvedEntities = await resolveEntities(
            description: transaction.description,
            date: transaction.postedAt
        )

        let descContext = DescriptionContext(
            merchantName: merchant.canonicalName,
            intent: ruleResult.intentPrediction.intent,
            isDebit: transaction.transactionType == .debit
        )
        let humanDescription = await descriptionGenerator.generate(from: descContext)

        return EnrichedTransaction(
            transaction: transaction,
            merchantCandidate: merchant,
            categoryPrediction: categoryPrediction,
            intentPrediction: ruleResult.intentPrediction,
            features: features,
            isUserCorrected: isUserCorrected,
            pipelineVersion: "1.0",
            resolvedEntities: resolvedEntities,
            humanDescription: humanDescription
        )
    }

    /// Run background post-processing on the full enriched corpus.
    /// Call after each import batch with ALL enriched transactions (not just the batch)
    /// so recurring detection sees the full history across all cadences (daily→yearly).
    public func postProcessBatch(
        enriched: [EnrichedTransaction],
        onStageChange: (@Sendable (PostProcessingStage) -> Void)? = nil
    ) async {
        guard let pipeline = postProcessingPipeline else { return }
        await pipeline.run(enriched: enriched, onStageChange: onStageChange)
    }

    public func trainClassifier(examples: [(text: String, categoryId: String)]) async throws {
        guard let classifier = personalizedClassifier else {
            throw NSError(
                domain: "FinanceIntelligence",
                code: 1,
                userInfo: [
                    NSLocalizedDescriptionKey: "PersonalizedClassifier unavailable — bundle resources may be missing " +
                        "(TransactionKNNClassifier.mlmodel, transaction_vocab.json)."
                ]
            )
        }
        FinanceLogger.intelligence.info("trainClassifier: \(examples.count) examples via MLUpdateTask")
        try await classifier.trainBatch(examples)
        FinanceLogger.intelligence.info("trainClassifier: complete")
        await registerKNNMetadata(classifier: classifier, examples: examples)
    }

    public func evaluateClassifier(
        examples: [(text: String, categoryId: String)]
    ) async -> ClassificationEvaluationResult? {
        guard let classifier = personalizedClassifier else { return nil }
        return await classifier.validateOnHeldOut(examples: examples)
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

        // 2. Emit feedback events for traceability
        try await feedbackStore.record(FeedbackEvent(
            eventType: .categoryCorrected,
            entityType: "transaction",
            entityId: transaction.id.uuidString,
            transactionId: transaction.id.uuidString,
            oldValue: previousPrediction?.categoryId,
            newValue: correctedCategoryId,
            modelVersion: previousPrediction?.modelVersion,
            configVersion: previousPrediction?.configVersion
        ))
        if let newMerchant = correctedMerchant, newMerchant != transaction.merchantName {
            try await feedbackStore.record(FeedbackEvent(
                eventType: .merchantCorrected,
                entityType: "transaction",
                entityId: transaction.id.uuidString,
                transactionId: transaction.id.uuidString,
                oldValue: transaction.merchantName,
                newValue: newMerchant,
                modelVersion: previousPrediction?.modelVersion,
                configVersion: previousPrediction?.configVersion
            ))
        }

        // 2. Add to on-device CoreML kNN via MLUpdateTask (primary personalization layer)
        let normalized = MerchantTextCleaner().normalizedForMatching(transaction.description)
        try await personalizedClassifier?.addExample(
            normalizedDescription: normalized,
            categoryId: correctedCategoryId
        )
    }
}

// swiftlint:enable type_body_length

// MARK: - Static Prediction (no actor needed — called from concurrent tasks)

extension TransactionIntelligenceServiceImpl {
    // swiftlint:disable:next function_parameter_count
    static func buildPrediction(
        features: TransactionFeatures,
        merchant: MerchantCandidate,
        personalized: PersonalizedClassifier?,
        coreML: CoreMLCategorizer?,
        rules: RuleBasedCategorizer,
        taxonomy: CategoryTaxonomy,
        knnThreshold: Double = IntelligenceConfig.defaultV1.classification.knnConfidenceThreshold,
        configVersion: String? = nil
    ) async -> CategoryPrediction {
        // Priority 1: on-device CoreML kNN (user corrections via MLUpdateTask)
        if let personalized,
           let knn = await personalized.predict(normalizedDescription: features.normalizedDescription),
           knn.confidence >= knnThreshold {
            let name = taxonomy.category(forId: knn.categoryId)?.displayName ?? knn.categoryId
            return CategoryPrediction(
                categoryId: knn.categoryId, subcategoryId: nil, displayName: name,
                confidence: knn.confidence, alternatives: [], source: .personalizedKNN,
                modelVersion: "personalized-knn", taxonomyVersion: taxonomy.version,
                confidenceKind: .uncalibratedScore, configVersion: configVersion
            )
        }
        // Priority 2: bundled NLModel text classifier
        if let coreML, coreML.isAvailable, let pred = coreML.predict(features: features) { return pred }
        // Priority 3: alias table
        if let categoryId = merchant.categoryId {
            let topLevel = categoryId.components(separatedBy: ".").first ?? categoryId
            let name = taxonomy.category(forId: topLevel)?.displayName ?? topLevel
            return CategoryPrediction(
                categoryId: topLevel, subcategoryId: categoryId, displayName: name,
                confidence: 0.88, alternatives: [], source: .personalizedKNN,
                modelVersion: ModelMetadata.rulesBased.modelVersion, taxonomyVersion: taxonomy.version,
                confidenceKind: .heuristicOrdinal, configVersion: configVersion
            )
        }
        // Priority 4: deterministic rules
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
           knn.confidence >= intelligenceConfig.classification.knnConfidenceThreshold {
            let name = taxonomy.category(forId: knn.categoryId)?.displayName ?? knn.categoryId
            return CategoryPrediction(
                categoryId: knn.categoryId, subcategoryId: nil, displayName: name,
                confidence: knn.confidence, alternatives: [], source: .personalizedKNN,
                modelVersion: "personalized-knn", taxonomyVersion: taxonomy.version,
                confidenceKind: .uncalibratedScore
            )
        }

        // Priority 2: bundled NLModel text classifier
        if let coreML = coreMLCategorizer, coreML.isAvailable,
           let prediction = coreML.predict(features: features) {
            return prediction
        }

        // Priority 3: alias table
        if let categoryId = merchantCategoryId {
            let topLevel = categoryId.components(separatedBy: ".").first ?? categoryId
            let name = taxonomy.category(forId: topLevel)?.displayName ?? topLevel
            return CategoryPrediction(
                categoryId: topLevel, subcategoryId: categoryId, displayName: name,
                confidence: 0.88, alternatives: [], source: .personalizedKNN,
                modelVersion: ModelMetadata.rulesBased.modelVersion, taxonomyVersion: taxonomy.version,
                confidenceKind: .heuristicOrdinal
            )
        }

        // Priority 4: deterministic rules
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
            taxonomyVersion: taxonomy.version,
            confidenceKind: .deterministic
        )
    }

    func registerKNNMetadata(
        classifier: PersonalizedClassifier,
        examples: [(text: String, categoryId: String)]
    ) async {
        let evalResult = await classifier.validateOnHeldOut(examples: examples)
        let hash = trainingDataHash(examples)
        let version = ModelMetadataEntry.knnVersion(trainedAt: Date(), trainingDataHash: hash)
        let confMatrixJson = (try? JSONEncoder().encode(evalResult.confusionMatrix))
            .flatMap { String(data: $0, encoding: .utf8) }
        let entry = ModelMetadataEntry(
            modelName: "personalized-knn",
            modelType: "knn",
            modelVersion: version,
            trainingExampleCount: examples.count,
            validationExampleCount: evalResult.validationCount,
            accuracy: evalResult.hasReliableMetrics ? evalResult.accuracy : nil,
            precisionMacro: evalResult.hasReliableMetrics ? evalResult.precisionMacro : nil,
            recallMacro: evalResult.hasReliableMetrics ? evalResult.recallMacro : nil,
            f1Macro: evalResult.hasReliableMetrics ? evalResult.f1Macro : nil,
            confusionMatrixJson: confMatrixJson,
            trainingDataHash: hash
        )
        await modelRegistry.register(entry)
    }

    func trainingDataHash(_ examples: [(text: String, categoryId: String)]) -> String {
        let payload = examples
            .sorted { $0.text < $1.text }
            .map { "\($0.text)|\($0.categoryId)" }
            .joined(separator: "\n")
        var hash: UInt64 = 14_695_981_039_346_656_037
        for byte in payload.utf8 {
            hash ^= UInt64(byte)
            hash &*= 1_099_511_628_211
        }
        return String(format: "%016llx", hash)
    }
}

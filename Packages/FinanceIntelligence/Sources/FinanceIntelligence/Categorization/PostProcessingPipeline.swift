import FinanceCore
import Foundation
import GRDB

/// Stage identifier for the post-processing pipeline.
/// Used in progress callbacks and audit logs.
public enum PostProcessingStage: String, Sendable, CustomStringConvertible {
    case graph = "knowledge_graph"
    case patterns = "recurring_patterns"
    case relationships = "relationship_inference"
    case complete

    public var description: String {
        switch self {
        case .graph: return "Building Knowledge Graph"
        case .patterns: return "Detecting Recurring Patterns"
        case .relationships: return "Inferring Relationships"
        case .complete: return "Complete"
        }
    }
}

/// Runs background intelligence enrichment after a transaction import batch:
///   1. Knowledge Graph update (PAID_TO/CLASSIFIED_AS edges)
///   2. Recurring pattern detection (≥2 occurrences, all cadences)
///   3. Relationship inference per person
///
/// Called by `TransactionIntelligenceServiceImpl.postProcessBatch()`.
/// All work is additive and idempotent — safe to re-run on the same data.
public actor PostProcessingPipeline {
    private let graphStore: GraphStore?
    private let recurringRepo: (any RecurringPatternRepository)?
    private let relationshipRepo: (any RelationshipRepository)?
    private let intelligenceConfig: IntelligenceConfig

    public init(
        graphStore: GraphStore?,
        recurringRepo: (any RecurringPatternRepository)?,
        relationshipRepo: (any RelationshipRepository)?,
        intelligenceConfig: IntelligenceConfig = .defaultV1
    ) {
        self.graphStore = graphStore
        self.recurringRepo = recurringRepo
        self.relationshipRepo = relationshipRepo
        self.intelligenceConfig = intelligenceConfig
    }

    /// Run all post-processing stages on a corpus of enriched transactions.
    /// - Parameter enriched: The FULL enriched transaction history (not just the latest batch)
    ///   so recurring detection can see patterns across time.
    /// Run all post-processing stages with typed stage reporting.
    /// - Parameter onStageChange: Called at the start of each stage for progress UI and logging.
    public func run(
        enriched: [EnrichedTransaction],
        onStageChange: (@Sendable (PostProcessingStage) -> Void)? = nil
    ) async {
        onStageChange?(.graph)
        FinanceLogger.intelligence
            .info("PostProcessing[\(PostProcessingStage.graph)]: starting, \(enriched.count) transactions")
        let (nodeCount, edgeCount) = await buildGraph(from: enriched)
        FinanceLogger.intelligence
            .info("PostProcessing[\(PostProcessingStage.graph)]: \(nodeCount) nodes, \(edgeCount) edges")

        onStageChange?(.patterns)
        FinanceLogger.intelligence.info("PostProcessing[\(PostProcessingStage.patterns)]: starting")
        let patterns = await detectRecurring(from: enriched)
        FinanceLogger.intelligence
            .info("PostProcessing[\(PostProcessingStage.patterns)]: \(patterns.count) patterns detected")

        onStageChange?(.relationships)
        FinanceLogger.intelligence.info("PostProcessing[\(PostProcessingStage.relationships)]: starting")
        let relationshipCount = await inferRelationships(from: enriched, patterns: patterns)
        FinanceLogger.intelligence
            .info("PostProcessing[\(PostProcessingStage.relationships)]: \(relationshipCount) relationships inferred")

        onStageChange?(.complete)
        let summary = "\(enriched.count) txns, \(patterns.count) patterns, \(relationshipCount) relationships"
        FinanceLogger.intelligence.info("PostProcessing[complete]: \(summary)")
    }

    // MARK: - Stage 1: Knowledge Graph

    private func buildGraph(from enriched: [EnrichedTransaction]) async -> (nodes: Int, edges: Int) {
        guard let store = graphStore else {
            FinanceLogger.intelligence.info("PostProcessing[graph]: skipped — no database configured")
            return (0, 0)
        }
        let builder = GraphBuilder(store: store)
        try? await builder.build(from: enriched)
        let nodes = await (try? store.nodes(ofType: .transaction).count) ?? 0
        let edges = nodes > 0 ? enriched.count * 2 : 0 // approximate: each txn → merchant + category
        return (nodes, edges)
    }

    // MARK: - Stage 2: Recurring Detection

    private func detectRecurring(from enriched: [EnrichedTransaction]) async -> [RecurringPattern] {
        let inputs = enriched.compactMap { makeDetectionInput(from: $0) }
        FinanceLogger.intelligence
            .info("PostProcessing[patterns]: \(inputs.count) detection inputs from \(enriched.count) transactions")
        guard inputs.count >= 2 else { return [] }
        let patterns = RecurringDetector(config: intelligenceConfig.recurring).detect(from: inputs)
        FinanceLogger.intelligence.info("PostProcessing[patterns]: saving \(patterns.count) patterns to DB")
        for pattern in patterns {
            let key = pattern.merchantKey ?? pattern.personId ?? "?"
            let conf = String(format: "%.2f", pattern.confidence)
            FinanceLogger.intelligence
                .info("PostProcessing[patterns]: \(key) — \(pattern.cadence.rawValue) — confidence \(conf)")
            try? await recurringRepo?.save(pattern)
            // externalId uses stable key so re-runs find-or-update rather than accumulate nodes
            let stableKey = pattern.merchantKey ?? pattern.personId ?? pattern.id.uuidString
            let stableId = "\(stableKey):\(pattern.cadence.rawValue)"
            _ = try? await graphStore?.upsertNode(GraphNode(
                nodeType: .recurringPattern,
                externalId: stableId,
                label: "\(pattern.merchantKey ?? pattern.personId ?? "pattern") (\(pattern.cadence.rawValue))"
            ))
        }
        return patterns
    }

    private func makeDetectionInput(from enriched: EnrichedTransaction) -> RecurringDetector.DetectionInput? {
        let merchant = enriched.merchantCandidate.canonicalName.lowercased()
        guard !merchant.isEmpty else { return nil }
        return RecurringDetector.DetectionInput(
            transactionId: enriched.transaction.id,
            merchantKey: merchant,
            personId: enriched.resolvedEntities?.personId?.uuidString,
            amountMinorUnits: abs(enriched.transaction.amountMinorUnits),
            postedAt: enriched.transaction.postedAt,
            categoryId: enriched.categoryPrediction.categoryId,
            intentId: enriched.intentPrediction.intent.rawValue
        )
    }

    // MARK: - Stage 3: Relationship Inference

    @discardableResult
    private func inferRelationships(from enriched: [EnrichedTransaction], patterns: [RecurringPattern]) async -> Int {
        guard let repo = relationshipRepo else {
            FinanceLogger.intelligence.info("PostProcessing[relationships]: skipped — no database configured")
            return 0
        }
        let salaryCreditDates = enriched
            .filter { $0.intentPrediction.intent == .salary && $0.transaction.transactionType == .credit }
            .map(\.transaction.postedAt)

        let byPerson = Dictionary(
            grouping: enriched.filter { $0.resolvedEntities?.personId != nil },
            by: { $0.resolvedEntities?.personId?.uuidString ?? "" }
        )
        FinanceLogger.intelligence.info(
            "PostProcessing[relationships]: \(byPerson.count) persons, \(salaryCreditDates.count) salary dates"
        )

        var saved = 0
        for (personId, txns) in byPerson where txns.count >= 2 {
            let personName = txns.first?.merchantCandidate.canonicalName ?? "Unknown"
            let patternForPerson = patterns.first { $0.personId == personId }
            let records = txns.map { enriched -> RelationshipEngine.TransactionRecord in
                RelationshipEngine.TransactionRecord(
                    amount: abs(enriched.transaction.amountMinorUnits),
                    isDebit: enriched.transaction.transactionType == .debit,
                    postedAt: enriched.transaction.postedAt,
                    rawDescription: enriched.transaction.description,
                    pattern: patternForPerson
                )
            }
            if let relationship = RelationshipEngine(config: intelligenceConfig.relationship).inferRelationship(
                personId: personId, personName: personName,
                transactions: records, salaryCreditDates: salaryCreditDates
            ) {
                let conf = String(format: "%.2f", relationship.confidence)
                FinanceLogger.intelligence
                    .info("PostProcessing[relationships]: \(personName) → \(relationship.type.rawValue) (\(conf))")
                try? await repo.save(relationship)
                saved += 1
            }
        }
        return saved
    }
}

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

    public init(
        graphStore: GraphStore?,
        recurringRepo: (any RecurringPatternRepository)?,
        relationshipRepo: (any RelationshipRepository)?
    ) {
        self.graphStore = graphStore
        self.recurringRepo = recurringRepo
        self.relationshipRepo = relationshipRepo
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
        FinanceLogger.intelligence.info("PostProcessing: \(PostProcessingStage.graph)")
        await buildGraph(from: enriched)

        onStageChange?(.patterns)
        FinanceLogger.intelligence.info("PostProcessing: \(PostProcessingStage.patterns)")
        let patterns = await detectRecurring(from: enriched)

        onStageChange?(.relationships)
        FinanceLogger.intelligence.info("PostProcessing: \(PostProcessingStage.relationships)")
        await inferRelationships(from: enriched, patterns: patterns)

        onStageChange?(.complete)
        FinanceLogger.intelligence
            .info("PostProcessing: \(PostProcessingStage.complete) (\(enriched.count) transactions)")
    }

    // MARK: - Stage 1: Knowledge Graph

    private func buildGraph(from enriched: [EnrichedTransaction]) async {
        guard let store = graphStore else { return }
        let builder = GraphBuilder(store: store)
        try? await builder.build(from: enriched)
    }

    // MARK: - Stage 2: Recurring Detection

    private func detectRecurring(from enriched: [EnrichedTransaction]) async -> [RecurringPattern] {
        let inputs = enriched.compactMap { makeDetectionInput(from: $0) }
        guard inputs.count >= 2 else { return [] }
        let patterns = RecurringDetector().detect(from: inputs)
        for pattern in patterns {
            try? await recurringRepo?.save(pattern)
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

    private func inferRelationships(from enriched: [EnrichedTransaction], patterns: [RecurringPattern]) async {
        guard let repo = relationshipRepo else { return }
        let salaryCreditDates = enriched
            .filter { $0.intentPrediction.intent == .salary && $0.transaction.transactionType == .credit }
            .map(\.transaction.postedAt)

        let byPerson = Dictionary(
            grouping: enriched.filter { $0.resolvedEntities?.personId != nil },
            by: { $0.resolvedEntities!.personId!.uuidString }
        )

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
            if let relationship = RelationshipEngine().inferRelationship(
                personId: personId, personName: personName,
                transactions: records, salaryCreditDates: salaryCreditDates
            ) {
                try? await repo.save(relationship)
            }
        }
    }
}

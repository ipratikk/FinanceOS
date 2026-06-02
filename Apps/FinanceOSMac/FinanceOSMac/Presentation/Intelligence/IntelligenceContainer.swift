import FinanceCore
import FinanceIntelligence
import Foundation
import GRDB

/// Lazily-initialized intelligence repository container for the Developer Hub.
/// Backed by `DatabaseManager.shared.dbQueue`. Keeps FinanceCore.AppContainer
/// free of FinanceIntelligence imports.
@MainActor
final class IntelligenceContainer {
    static let shared = IntelligenceContainer()

    let personRepository: any IntelligencePersonRepository
    let relationshipRepository: any RelationshipRepository
    let recurringPatternRepository: any RecurringPatternRepository
    let graphRepository: any GraphRepository
    let feedbackStore: any FeedbackStore
    let datasetOrchestrator: DatasetOrchestrator

    private init() {
        let queue = DatabaseManager.shared.dbQueue
        personRepository = GRDBIntelligencePersonRepository(dbQueue: queue)
        relationshipRepository = GRDBRelationshipRepository(dbWriter: queue)
        recurringPatternRepository = GRDBRecurringPatternRepository(dbWriter: queue)
        graphRepository = GRDBGraphRepository(dbWriter: queue)
        feedbackStore = GRDBFeedbackStore(dbQueue: queue)
        datasetOrchestrator = DatasetOrchestrator()
    }
}

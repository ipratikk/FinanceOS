import FinanceCore
import Foundation
import GRDB

/// Persists intelligence inference events to `intelligence_inference_events` (INTEL-001 migration).
public final class GRDBIntelligenceLogger: @unchecked Sendable, IntelligenceLogger {
    private let dbQueue: DatabaseQueue

    public init(dbQueue: DatabaseQueue) {
        self.dbQueue = dbQueue
    }

    public func record(_ event: IntelligenceEvent) async {
        do {
            try await dbQueue.write { db in
                try GRDBInferenceEvent(event: event).insert(db)
            }
        } catch {
            FinanceLogger.intelligence.error("GRDBIntelligenceLogger write failed: \(error)")
        }
    }
}

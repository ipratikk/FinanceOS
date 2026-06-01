import Foundation

/// Persists user feedback signals that drive future model improvement.
public protocol FeedbackStore: Sendable {
    func record(_ event: FeedbackEvent) async throws
    func events(for transactionId: UUID) async throws -> [FeedbackEvent]
    func events(ofType type: FeedbackEventType) async throws -> [FeedbackEvent]
    func allEvents() async throws -> [FeedbackEvent]
}

/// No-op implementation used when no database is configured.
public struct NullFeedbackStore: FeedbackStore {
    public init() {}
    public func record(_ event: FeedbackEvent) async throws {}
    public func events(for transactionId: UUID) async throws -> [FeedbackEvent] {
        []
    }

    public func events(ofType type: FeedbackEventType) async throws -> [FeedbackEvent] {
        []
    }

    public func allEvents() async throws -> [FeedbackEvent] {
        []
    }
}

import Foundation

/// Classifies every type of user action that produces a feedback signal.
public enum FeedbackEventType: String, Codable, Sendable, CaseIterable {
    // Category / merchant corrections
    case categoryCorrected
    case merchantCorrected

    // Person entity management
    case personMerged
    case personRenamed

    // Relationship signals
    case relationshipConfirmed
    case relationshipRejected
    case relationshipCorrected

    // Recurring pattern signals
    case recurringConfirmed
    case recurringRejected

    // Insight engagement signals
    case insightOpened
    case insightDismissed
    case insightIgnored
    case insightActionTaken
}

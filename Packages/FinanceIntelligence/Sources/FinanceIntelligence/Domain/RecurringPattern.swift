import Foundation

/// A detected recurring payment pattern between the user and a merchant or person.
/// Confidence reflects how consistently the cadence, amount, and timing match.
public struct RecurringPattern: Identifiable, Sendable, Codable {
    public let id: UUID
    public let merchantKey: String?
    public let personId: String?
    public let categoryId: String
    public let intentId: String
    public var cadence: RecurringCadence
    public var averageAmountMinorUnits: Int64
    public var amountVariancePercent: Double
    public var dayOfMonthHint: Int?
    public var confidence: Double
    public var occurrenceCount: Int
    public var lastSeenAt: Date
    public let createdAt: Date

    public init(
        id: UUID = UUID(),
        merchantKey: String? = nil,
        personId: String? = nil,
        categoryId: String,
        intentId: String,
        cadence: RecurringCadence,
        averageAmountMinorUnits: Int64,
        amountVariancePercent: Double = 0,
        dayOfMonthHint: Int? = nil,
        confidence: Double,
        occurrenceCount: Int,
        lastSeenAt: Date,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.merchantKey = merchantKey
        self.personId = personId
        self.categoryId = categoryId
        self.intentId = intentId
        self.cadence = cadence
        self.averageAmountMinorUnits = averageAmountMinorUnits
        self.amountVariancePercent = amountVariancePercent
        self.dayOfMonthHint = dayOfMonthHint
        self.confidence = confidence
        self.occurrenceCount = occurrenceCount
        self.lastSeenAt = lastSeenAt
        self.createdAt = createdAt
    }
}

public enum RecurringCadence: String, Codable, Sendable, CaseIterable {
    case weekly
    case biWeekly = "bi_weekly"
    case monthly
    case quarterly
    case yearly
    case irregular

    public var targetIntervalDays: Double {
        switch self {
        case .weekly: return 7
        case .biWeekly: return 14
        case .monthly: return 30.44
        case .quarterly: return 91.31
        case .yearly: return 365.25
        case .irregular: return 0
        }
    }

    public var toleranceDays: Double {
        switch self {
        case .weekly: return 2
        case .biWeekly: return 3
        case .monthly: return 5
        case .quarterly: return 10
        case .yearly: return 20
        case .irregular: return .infinity
        }
    }
}

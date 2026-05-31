import Foundation
import GRDB

struct GRDBRecurringPattern: Codable, FetchableRecord, PersistableRecord {
    static let databaseTableName = "recurring_patterns"

    var id: String
    var merchantKey: String?
    var personId: String?
    var categoryId: String
    var intentId: String
    var cadence: String
    var averageAmountMinorUnits: Int64
    var amountVariancePercent: Double
    var dayOfMonthHint: Int?
    var confidence: Double
    var occurrenceCount: Int
    var lastSeenAt: Date
    var createdAt: Date

    init(from pattern: RecurringPattern) {
        id = pattern.id.uuidString
        merchantKey = pattern.merchantKey
        personId = pattern.personId
        categoryId = pattern.categoryId
        intentId = pattern.intentId
        cadence = pattern.cadence.rawValue
        averageAmountMinorUnits = pattern.averageAmountMinorUnits
        amountVariancePercent = pattern.amountVariancePercent
        dayOfMonthHint = pattern.dayOfMonthHint
        confidence = pattern.confidence
        occurrenceCount = pattern.occurrenceCount
        lastSeenAt = pattern.lastSeenAt
        createdAt = pattern.createdAt
    }

    func toDomain() -> RecurringPattern? {
        guard let uuid = UUID(uuidString: id),
              let cadenceVal = RecurringCadence(rawValue: cadence) else { return nil }
        return RecurringPattern(
            id: uuid, merchantKey: merchantKey, personId: personId,
            categoryId: categoryId, intentId: intentId, cadence: cadenceVal,
            averageAmountMinorUnits: averageAmountMinorUnits,
            amountVariancePercent: amountVariancePercent,
            dayOfMonthHint: dayOfMonthHint, confidence: confidence,
            occurrenceCount: occurrenceCount, lastSeenAt: lastSeenAt, createdAt: createdAt
        )
    }
}

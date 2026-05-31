import Foundation

/// Predicts the next expected date for a recurring pattern.
public struct ScheduleInference: Sendable {
    public init() {}

    public func nextDate(after lastDate: Date, cadence: RecurringCadence, dayOfMonthHint: Int? = nil) -> Date? {
        let cal = Calendar.current
        switch cadence {
        case .weekly: return cal.date(byAdding: .day, value: 7, to: lastDate)
        case .biWeekly: return cal.date(byAdding: .day, value: 14, to: lastDate)
        case .monthly:
            if let day = dayOfMonthHint {
                var comps = cal.dateComponents([.year, .month], from: lastDate)
                comps.month = (comps.month ?? 1) + 1
                comps.day = day
                return cal.date(from: comps)
            }
            return cal.date(byAdding: .month, value: 1, to: lastDate)
        case .quarterly: return cal.date(byAdding: .month, value: 3, to: lastDate)
        case .yearly: return cal.date(byAdding: .year, value: 1, to: lastDate)
        case .irregular: return nil
        }
    }
}

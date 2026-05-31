import Foundation

/// Infers recurring cadence from a sequence of transaction dates using median interval.
public struct PatternAnalyzer: Sendable {
    public init() {}

    public func analyzeCadence(dates: [Date]) -> (cadence: RecurringCadence, confidence: Double)? {
        guard dates.count >= 2 else { return nil }
        let sorted = dates.sorted()
        let intervals = zip(sorted.dropFirst(), sorted).map { $0.timeIntervalSince($1) / 86400 }
        let median = medianValue(intervals)
        return matchCadence(medianIntervalDays: median, sampleCount: intervals.count)
    }

    public func dayOfMonthHint(from dates: [Date]) -> Int? {
        guard !dates.isEmpty else { return nil }
        let days = dates.map { Calendar.current.component(.day, from: $0) }.sorted()
        return days[days.count / 2]
    }

    // MARK: - Private

    private func medianValue(_ values: [Double]) -> Double {
        guard !values.isEmpty else { return 0 }
        let sorted = values.sorted()
        let mid = sorted.count / 2
        return sorted.count.isMultiple(of: 2) ? (sorted[mid - 1] + sorted[mid]) / 2 : sorted[mid]
    }

    private func matchCadence(
        medianIntervalDays: Double,
        sampleCount: Int
    ) -> (cadence: RecurringCadence, confidence: Double) {
        let candidates: [RecurringCadence] = [.weekly, .biWeekly, .monthly, .quarterly, .yearly]
        for cadence in candidates {
            let deviation = abs(medianIntervalDays - cadence.targetIntervalDays)
            if deviation <= cadence.toleranceDays {
                let sampleBonus = min(Double(sampleCount) / 12.0, 1.0) * 0.2
                let deviationPenalty = deviation / cadence.toleranceDays * 0.15
                return (cadence, min(0.75 + sampleBonus - deviationPenalty, 0.95))
            }
        }
        return (.irregular, 0.3)
    }
}

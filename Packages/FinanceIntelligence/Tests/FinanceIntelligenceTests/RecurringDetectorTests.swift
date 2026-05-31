import Foundation
import Testing

@testable import FinanceIntelligence

@Suite("RecurringDetector — cadence and pattern detection")
struct RecurringDetectorTests {
    private let detector = RecurringDetector()
    private let analyzer = PatternAnalyzer()
    private let schedule = ScheduleInference()

    @Test("Monthly Spotify: 12 occurrences → monthly cadence ≥ 0.85 confidence")
    func spotifyMonthlyRecurring() {
        let dates = (0..<12).map { Calendar.current.date(byAdding: .month, value: -$0, to: Date())! }
        let result = analyzer.analyzeCadence(dates: dates)
        #expect(result?.cadence == .monthly)
        #expect((result?.confidence ?? 0) >= 0.85)
    }

    @Test("Weekly transfers: 8 occurrences → weekly cadence")
    func weeklyDetected() {
        let dates = (0..<8).map { Calendar.current.date(byAdding: .weekOfYear, value: -$0, to: Date())! }
        #expect(analyzer.analyzeCadence(dates: dates)?.cadence == .weekly)
    }

    @Test("Yearly insurance: 2 occurrences → yearly cadence")
    func yearlyDetected() {
        let now = Date()
        let lastYear = Calendar.current.date(byAdding: .year, value: -1, to: now)!
        #expect(analyzer.analyzeCadence(dates: [lastYear, now])?.cadence == .yearly)
    }

    @Test("Single date returns nil")
    func singleDateNil() {
        #expect(analyzer.analyzeCadence(dates: [Date()]) == nil)
    }

    @Test("Detector: Spotify 12× monthly → pattern with confidence ≥ 0.85")
    func detectorSpotifyMonthly() {
        let inputs = (0..<12).map { i -> RecurringDetector.DetectionInput in
            let date = Calendar.current.date(byAdding: .month, value: -i, to: Date())!
            return RecurringDetector.DetectionInput(
                transactionId: UUID(), merchantKey: "spotify",
                amountMinorUnits: 13900, postedAt: date,
                categoryId: "subscriptions", intentId: "subscription"
            )
        }
        let patterns = detector.detect(from: inputs)
        let spotify = patterns.first { $0.merchantKey == "spotify" }
        #expect(spotify?.cadence == .monthly)
        #expect((spotify?.confidence ?? 0) >= 0.85)
        #expect(spotify?.occurrenceCount == 12)
    }

    @Test("Amount variance low for stable amounts")
    func lowVarianceStableAmounts() {
        let inputs = (0..<6).map { i -> RecurringDetector.DetectionInput in
            let date = Calendar.current.date(byAdding: .month, value: -i, to: Date())!
            return RecurringDetector.DetectionInput(
                transactionId: UUID(), merchantKey: "rent",
                amountMinorUnits: 2200000 + Int64(i * 5000),
                postedAt: date, categoryId: "housing", intentId: "rent"
            )
        }
        let pattern = detector.detect(from: inputs).first
        #expect(pattern?.amountVariancePercent ?? 1.0 < 0.05)
    }

    @Test("Monthly schedule predicts correct next date")
    func monthlySchedule() {
        let last = Calendar.current.date(from: DateComponents(year: 2025, month: 3, day: 25))!
        let next = schedule.nextDate(after: last, cadence: .monthly, dayOfMonthHint: 25)
        let comps = Calendar.current.dateComponents([.month, .day], from: next!)
        #expect(comps.month == 4)
        #expect(comps.day == 25)
    }

    @Test("Weekly schedule predicts 7 days ahead")
    func weeklySchedule() {
        let last = Date()
        let next = schedule.nextDate(after: last, cadence: .weekly)
        #expect(abs((next!.timeIntervalSince(last) / 86400) - 7) < 1)
    }

    @Test("Irregular returns nil next date")
    func irregularNil() {
        #expect(schedule.nextDate(after: Date(), cadence: .irregular) == nil)
    }
}

@testable import FinanceCore
import Foundation
import Testing

private let utc: Calendar = {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "UTC") ?? .current
    return calendar
}()

private func day(_ value: String) -> Date {
    let formatter = DateFormatter()
    formatter.calendar = utc
    formatter.timeZone = utc.timeZone
    formatter.dateFormat = "yyyy-MM-dd"
    return formatter.date(from: value) ?? Date(timeIntervalSince1970: 0)
}

private func input(
    id: String,
    name: String,
    kind: LedgerKind = .bankAccount,
    balance: Int64? = 10000,
    last: Date?
) -> StatementLedgerInput {
    StatementLedgerInput(
        ledgerId: id,
        displayName: name,
        kind: kind,
        last4: "1234",
        bankName: "HDFC",
        balanceMinor: balance,
        currencyCode: "INR",
        lastStatementDate: last
    )
}

@Test
func statementLevelFollowsPolicyWindows() {
    let now = day("2026-11-16")
    let policy = StatementStalenessPolicy.standard // bank max 35, due window 7

    let fresh = StatementStatusEvaluator.evaluate(
        [input(id: "a", name: "A", last: day("2026-11-01"))], now: now, policy: policy, calendar: utc
    )
    #expect(fresh.first?.level == .fresh)
    #expect(fresh.first?.daysSinceStatement == 15)

    let due = StatementStatusEvaluator.evaluate(
        [input(id: "a", name: "A", last: day("2026-10-12"))], now: now, policy: policy, calendar: utc
    )
    #expect(due.first?.level == .due) // 35 days: at the limit, not over it, inside the 7-day due window

    let overdue = StatementStatusEvaluator.evaluate(
        [input(id: "a", name: "A", last: day("2026-09-01"))], now: now, policy: policy, calendar: utc
    )
    #expect(overdue.first?.level == .overdue)
}

@Test
func missingStatementIsUnknownAndNeedsAction() {
    let statuses = StatementStatusEvaluator.evaluate(
        [input(id: "a", name: "A", last: nil)], now: day("2026-11-16"), calendar: utc
    )
    #expect(statuses.first?.level == .unknown)
    #expect(statuses.first?.daysSinceStatement == nil)
    #expect(statuses.first?.level.needsAction == true)
}

@Test
func investmentsUseLongerWindow() {
    let now = day("2026-11-16")
    let statuses = StatementStatusEvaluator.evaluate(
        [input(id: "mf", name: "MF", kind: .investment, last: day("2026-09-01"))],
        now: now,
        calendar: utc
    )
    // 76 days old: overdue for bank (35) but fresh for investment (90 - 7 window = 83)
    #expect(statuses.first?.level == .fresh)
}

@Test
func outputSortsActionableFirstThenName() {
    let now = day("2026-11-16")
    let statuses = StatementStatusEvaluator.evaluate([
        input(id: "1", name: "Zeta", last: day("2026-11-10")),
        input(id: "2", name: "Beta", last: nil),
        input(id: "3", name: "Alpha", last: day("2026-08-01"))
    ], now: now, calendar: utc)

    #expect(statuses.map(\.displayName) == ["Alpha", "Beta", "Zeta"])
    #expect(statuses.map(\.level) == [.overdue, .unknown, .fresh])
}

@Test
func minorUnitsFormatAsDecimal() {
    #expect(DashboardDatasetExporter.decimalString(minor: 1_234_560) == "12345.60")
    #expect(DashboardDatasetExporter.decimalString(minor: 5) == "0.05")
    #expect(DashboardDatasetExporter.decimalString(minor: -250) == "-2.50")
    #expect(DashboardDatasetExporter.decimalString(minor: 0) == "0.00")
}

@Test
func csvEscapesCommasQuotesAndNewlines() {
    #expect(DashboardDatasetExporter.escapeCSV("plain") == "plain")
    #expect(DashboardDatasetExporter.escapeCSV("Pratik, Savings") == "\"Pratik, Savings\"")
    #expect(DashboardDatasetExporter.escapeCSV("say \"hi\"") == "\"say \"\"hi\"\"\"")
    #expect(DashboardDatasetExporter.escapeCSV("a\nb") == "\"a\nb\"")
}

@Test
func csvHasHeaderAndOneRowPerLedger() {
    let statuses = StatementStatusEvaluator.evaluate([
        input(id: "1", name: "HDFC, Main", balance: 250_000, last: day("2026-11-10")),
        input(id: "2", name: "Card", balance: nil, last: nil)
    ], now: day("2026-11-16"), calendar: utc)

    let lines = DashboardDatasetExporter.csv(from: statuses).split(separator: "\n").map(String.init)
    #expect(lines.count == 3)
    #expect(lines[0] == DashboardDatasetExporter.csvHeader.joined(separator: ","))
    // Sorted actionable-first: unknown (Card) before fresh (HDFC).
    #expect(lines[1] == "2,Card,bankAccount,HDFC,1234,,INR,,,unknown,true")
    #expect(lines[2] == "1,\"HDFC, Main\",bankAccount,HDFC,1234,2500.00,INR,2026-11-10,6,fresh,false")
}

@Test
func jsonIsDeterministicAndVersioned() throws {
    let now = day("2026-11-16")
    let statuses = StatementStatusEvaluator.evaluate(
        [input(id: "1", name: "A", last: day("2026-11-10"))], now: now, calendar: utc
    )
    let first = try DashboardDatasetExporter.jsonData(from: statuses, generatedAt: now)
    let second = try DashboardDatasetExporter.jsonData(from: statuses, generatedAt: now)
    #expect(first == second)

    let decoded = try JSONDecoder.iso8601Decoder().decode(DashboardDatasetExporter.Dataset.self, from: first)
    #expect(decoded.schemaVersion == DashboardDatasetExporter.schemaVersion)
    #expect(decoded.ledgers.first?.lastStatementDate == "2026-11-10")
}

@Test
func reminderLinkRoundTripsLedgerTarget() throws {
    let ledgerId = "CC-1A2B3C4D"
    let url = try #require(StatementReminderLink.importURL(for: ledgerId))
    #expect(url.absoluteString == "financeos://import/CC-1A2B3C4D")
    #expect(StatementReminderLink.importTarget(from: url) == .ledger(ledgerId))
}

@Test
func reminderLinkRejectsForeignOrMalformedURLs() throws {
    let rejected = [
        "https://import/11111111-2222-3333-4444-555555555555",
        "financeos://dashboard/11111111-2222-3333-4444-555555555555",
        "financeos://import/not-a-uuid",
        "financeos://import",
        "financeos://import/11111111-2222-3333-4444-555555555555/extra"
    ]
    for text in rejected {
        let url = try #require(URL(string: text))
        #expect(StatementReminderLink.importTarget(from: url) == nil, "\(text) should be rejected")
    }
}

private extension JSONDecoder {
    static func iso8601Decoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}

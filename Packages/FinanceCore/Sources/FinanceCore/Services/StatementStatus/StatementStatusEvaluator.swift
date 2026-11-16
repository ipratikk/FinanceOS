import Foundation

/// Pure, deterministic freshness evaluation. No I/O; `now` and `calendar` are injected for testing.
public enum StatementStatusEvaluator {
    public static func evaluate(
        _ inputs: [StatementLedgerInput],
        now: Date,
        policy: StatementStalenessPolicy = .standard,
        calendar: Calendar = .current
    ) -> [StatementStatus] {
        inputs
            .map { status(for: $0, now: now, policy: policy, calendar: calendar) }
            .sorted { lhs, rhs in
                if lhs.level.sortRank != rhs.level.sortRank {
                    return lhs.level.sortRank < rhs.level.sortRank
                }
                return lhs.displayName.localizedStandardCompare(rhs.displayName) == .orderedAscending
            }
    }

    static func status(
        for input: StatementLedgerInput,
        now: Date,
        policy: StatementStalenessPolicy,
        calendar: Calendar
    ) -> StatementStatus {
        let days = input.lastStatementDate.flatMap { lastDate in
            calendar.dateComponents([.day], from: lastDate, to: now).day
        }
        return StatementStatus(
            ledgerId: input.ledgerId,
            displayName: input.displayName,
            kind: input.kind,
            last4: input.last4,
            bankName: input.bankName,
            balanceMinor: input.balanceMinor,
            currencyCode: input.currencyCode,
            lastStatementDate: input.lastStatementDate,
            daysSinceStatement: days,
            level: level(daysSince: days, kind: input.kind, policy: policy)
        )
    }

    static func level(daysSince: Int?, kind: LedgerKind, policy: StatementStalenessPolicy) -> StatementStatusLevel {
        guard let days = daysSince else { return .unknown }
        let maxAge = policy.maxAge(for: kind)
        if days > maxAge { return .overdue }
        if days >= maxAge - policy.dueWindowDays { return .due }
        return .fresh
    }
}

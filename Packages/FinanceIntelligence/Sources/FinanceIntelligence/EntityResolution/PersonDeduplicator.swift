import Foundation

/// Identifies near-duplicate person entities from a corpus of known persons.
///
/// Match tiers (conservative):
/// - `exactCaseInsensitive`: uppercased names are identical
/// - `strongMatch`: Levenshtein edit distance ≤ 2 on normalized name
/// - `possibleMatch`: token Jaccard similarity ≥ 0.7
/// - `noMatch`: below all thresholds
///
/// Only `exactCaseInsensitive` and `strongMatch` are auto-merge candidates.
/// `possibleMatch` surfaces for human review only.
public struct PersonDeduplicator: Sendable {
    public enum MatchType: String, Sendable, Comparable {
        case exactCaseInsensitive
        case strongMatch
        case possibleMatch
        case noMatch

        public static func < (lhs: Self, rhs: Self) -> Bool {
            let order: [MatchType] = [.exactCaseInsensitive, .strongMatch, .possibleMatch, .noMatch]
            return (order.firstIndex(of: lhs) ?? 0) < (order.firstIndex(of: rhs) ?? 0)
        }

        public var isAutoMergeCandidate: Bool {
            self == .exactCaseInsensitive || self == .strongMatch
        }
    }

    public struct Candidate: Sendable {
        public let existingId: UUID
        public let existingName: String
        public let matchType: MatchType
        public let editDistance: Int?
        public let jaccardSimilarity: Double?
    }

    public init() {}

    /// Returns dedup candidates for `name` from `persons`, sorted best-match first.
    /// Input names are sanitized via `NameSanitizer` before comparison.
    public func findCandidates(for name: String, in persons: [Person]) -> [Candidate] {
        let normalized = NameSanitizer.sanitize(name)
        guard !normalized.isEmpty else { return [] }

        return persons.compactMap { person in
            let existingNormalized = NameSanitizer.sanitize(person.canonicalName)
            guard !existingNormalized.isEmpty else { return nil }
            return score(
                input: normalized, existing: existingNormalized,
                personId: person.id, personName: person.canonicalName
            )
        }
        .filter { $0.matchType != .noMatch }
        .sorted { $0.matchType < $1.matchType }
    }
}

// MARK: - Scoring

private extension PersonDeduplicator {
    func score(
        input: String,
        existing: String,
        personId: UUID,
        personName: String
    ) -> Candidate {
        if input == existing {
            return Candidate(
                existingId: personId, existingName: personName,
                matchType: .exactCaseInsensitive, editDistance: 0, jaccardSimilarity: 1.0
            )
        }

        let dist = levenshtein(input, existing)
        if dist <= 2 {
            return Candidate(
                existingId: personId, existingName: personName,
                matchType: .strongMatch, editDistance: dist, jaccardSimilarity: nil
            )
        }

        let jaccard = tokenJaccard(input, existing)
        if jaccard >= 0.7 {
            return Candidate(
                existingId: personId, existingName: personName,
                matchType: .possibleMatch, editDistance: nil, jaccardSimilarity: jaccard
            )
        }

        return Candidate(
            existingId: personId, existingName: personName,
            matchType: .noMatch, editDistance: nil, jaccardSimilarity: nil
        )
    }

    func levenshtein(_ a: String, _ b: String) -> Int {
        let aChars = Array(a), bChars = Array(b)
        let m = aChars.count, n = bChars.count
        guard m > 0 else { return n }
        guard n > 0 else { return m }
        // Early-exit: length difference alone exceeds threshold
        if abs(m - n) > 3 { return abs(m - n) }

        var dp = Array(0 ... n)
        for i in 1 ... m {
            var prev = dp[0]
            dp[0] = i
            for j in 1 ... n {
                let temp = dp[j]
                dp[j] = aChars[i - 1] == bChars[j - 1]
                    ? prev
                    : 1 + min(prev, dp[j], dp[j - 1])
                prev = temp
            }
        }
        return dp[n]
    }

    func tokenJaccard(_ a: String, _ b: String) -> Double {
        let tokA = Set(a.components(separatedBy: .whitespaces).filter { !$0.isEmpty })
        let tokB = Set(b.components(separatedBy: .whitespaces).filter { !$0.isEmpty })
        guard !tokA.isEmpty, !tokB.isEmpty else { return 0 }
        return Double(tokA.intersection(tokB).count) / Double(tokA.union(tokB).count)
    }
}

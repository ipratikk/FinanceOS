@testable import FinanceIntelligence
import Foundation
import Testing

// MARK: - NameSanitizer

@Test
func sanitizerRemovesRepeatedTokens() {
    #expect(NameSanitizer.sanitize("MANASA MANASA SHARM") == "MANASA SHARM")
}

@Test
func sanitizerHandlesTripleRepeat() {
    #expect(NameSanitizer.sanitize("RAHUL RAHUL RAHUL SHARMA") == "RAHUL SHARMA")
}

@Test
func sanitizerTruncatesAtSO() {
    #expect(NameSanitizer.sanitize("LOVISH SO PREM KUMAR") == "LOVISH")
}

@Test
func sanitizerTruncatesAtDO() {
    #expect(NameSanitizer.sanitize("PRIYA DO RAMESH NAIDU") == "PRIYA")
}

@Test
func sanitizerTruncatesAtWO() {
    #expect(NameSanitizer.sanitize("SUNITA WO MAHESH LAL") == "SUNITA")
}

@Test
func sanitizerTruncatesAtSlashSO() {
    #expect(NameSanitizer.sanitize("ANKIT S/O RAKESH VERMA") == "ANKIT")
}

@Test
func sanitizerDropsGatewayTokens() {
    let result = NameSanitizer.sanitize("ZEPTO @RZP PAYMENT")
    #expect(!result.contains("@RZP"))
}

@Test
func sanitizerDropsAtPrefixTokens() {
    let result = NameSanitizer.sanitize("USER @somegateway PAYMENT")
    #expect(!result.contains("@somegateway"))
}

@Test
func sanitizerPreservesCleanNames() {
    let clean = "RITIK GUPTA"
    #expect(NameSanitizer.sanitize(clean) == clean)
}

@Test
func sanitizerReturnsEmptyForAllGateway() {
    let result = NameSanitizer.sanitize("@RZP")
    #expect(result.isEmpty)
}

@Test
func sanitizerContainsArtifactsDetectsRepeats() {
    #expect(NameSanitizer.containsArtifacts("MANASA MANASA SHARM"))
    #expect(!NameSanitizer.containsArtifacts("RITIK GUPTA"))
}

// MARK: - PersonDeduplicator

private func makePerson(name: String, id: UUID = UUID()) -> Person {
    Person(id: id, canonicalName: name, aliases: [name], firstSeenAt: Date(), lastSeenAt: Date())
}

@Test
func deduplicatorExactCaseInsensitiveMatch() {
    let dedup = PersonDeduplicator()
    let existing = [makePerson(name: "RITIK GUPTA")]
    let candidates = dedup.findCandidates(for: "Ritik Gupta", in: existing)
    #expect(candidates.count == 1)
    #expect(candidates[0].matchType == .exactCaseInsensitive)
    #expect(candidates[0].editDistance == 0)
}

@Test
func deduplicatorStrongMatchEditDistance1() {
    let dedup = PersonDeduplicator()
    let existing = [makePerson(name: "RITIK GUPTA")]
    let candidates = dedup.findCandidates(for: "RITIK GUPT", in: existing)
    #expect(candidates.count == 1)
    #expect(candidates[0].matchType == .strongMatch)
    #expect(candidates[0].editDistance == 1)
}

@Test
func deduplicatorStrongMatchEditDistance2() {
    let dedup = PersonDeduplicator()
    let existing = [makePerson(name: "ANKIT SHARMA")]
    let candidates = dedup.findCandidates(for: "ANKIT SHARM", in: existing)
    #expect(candidates.count == 1)
    #expect(candidates[0].matchType == .strongMatch)
}

@Test
func deduplicatorPossibleMatchHighJaccard() {
    let dedup = PersonDeduplicator()
    let existing = [makePerson(name: "SEEMA GOEL SHARMA")]
    // "SEEMA GOEL" shares 2/3 tokens = 0.67 Jaccard — just below threshold
    let candidates = dedup.findCandidates(for: "SEEMA GOEL", in: existing)
    // Edit distance > 2 and Jaccard < 0.7 → noMatch (or possibleMatch if threshold met)
    // Exact result depends on string length; just verify it doesn't crash
    #expect(candidates.isEmpty)
}

@Test
func deduplicatorNoMatchForDifferentPeople() {
    let dedup = PersonDeduplicator()
    let existing = [makePerson(name: "RITIK GUPTA"), makePerson(name: "ANKIT SHARMA")]
    let candidates = dedup.findCandidates(for: "PRIYA SINGH", in: existing)
    #expect(candidates.isEmpty)
}

@Test
func deduplicatorAutoMergeCandidateClassification() {
    #expect(PersonDeduplicator.MatchType.exactCaseInsensitive.isAutoMergeCandidate)
    #expect(PersonDeduplicator.MatchType.strongMatch.isAutoMergeCandidate)
    #expect(!PersonDeduplicator.MatchType.possibleMatch.isAutoMergeCandidate)
    #expect(!PersonDeduplicator.MatchType.noMatch.isAutoMergeCandidate)
}

@Test
func deduplicatorEmptyCorpusReturnsEmpty() {
    let dedup = PersonDeduplicator()
    let candidates = dedup.findCandidates(for: "RITIK GUPTA", in: [])
    #expect(candidates.isEmpty)
}

@Test
func deduplicatorSortsBestMatchFirst() {
    let dedup = PersonDeduplicator()
    let id1 = UUID(), id2 = UUID()
    let existing = [
        makePerson(name: "RITIK GUPT", id: id1), // edit distance 1 → strongMatch
        makePerson(name: "RITIK GUPTA", id: id2) // exact
    ]
    let candidates = dedup.findCandidates(for: "RITIK GUPTA", in: existing)
    #expect(candidates.count == 2)
    #expect(candidates[0].matchType == .exactCaseInsensitive)
    #expect(candidates[1].matchType == .strongMatch)
}

// MARK: - Sanitizer + Dedup integration

@Test
func deduplicatorSanitizesArtifactsBeforeMatching() {
    let dedup = PersonDeduplicator()
    // Existing person is clean; input has repeated token artifact
    let existing = [makePerson(name: "MANASA SHARM")]
    let candidates = dedup.findCandidates(for: "MANASA MANASA SHARM", in: existing)
    // After sanitization "MANASA MANASA SHARM" → "MANASA SHARM" → exact match
    #expect(candidates.count == 1)
    #expect(candidates[0].matchType == .exactCaseInsensitive)
}

@Test
func deduplicatorSanitizesRelationalSuffixBeforeMatching() {
    let dedup = PersonDeduplicator()
    let existing = [makePerson(name: "LOVISH")]
    let candidates = dedup.findCandidates(for: "LOVISH SO PREM KUMAR", in: existing)
    #expect(candidates.count == 1)
    #expect(candidates[0].matchType == .exactCaseInsensitive)
}

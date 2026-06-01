@testable import FinanceIntelligence
import XCTest

final class ConfidenceDisplayPolicyTests: XCTestCase {
    private let policy = ConfidenceDisplayPolicy()

    // MARK: - deterministic

    func testDeterministicAlwaysShowsRuleLabel() {
        let display = policy.displayLabel(confidence: 1.0, confidenceKind: .deterministic, source: .structuralRule)
        XCTAssertEqual(display, .label("Matched a known bank pattern"))
    }

    func testDeterministicIgnoresConfidenceValue() {
        let display = policy.displayLabel(confidence: 0.5, confidenceKind: .deterministic, source: .structuralRule)
        XCTAssertEqual(display, .label("Matched a known bank pattern"))
    }

    // MARK: - calibratedProbability

    func testCalibratedHighConfidenceShowsPercentage() {
        let display = policy.displayLabel(
            confidence: 0.95, confidenceKind: .calibratedProbability, source: .coreMLNLModel
        )
        XCTAssertEqual(display, .label("95%"))
    }

    func testCalibratedModerateConfidenceShowsLabel() {
        let display = policy.displayLabel(
            confidence: 0.62, confidenceKind: .calibratedProbability, source: .coreMLNLModel
        )
        XCTAssertEqual(display, .label("Moderate confidence"))
    }

    func testCalibratedLowConfidenceShowsNeedsReview() {
        let display = policy.displayLabel(
            confidence: 0.3, confidenceKind: .calibratedProbability, source: .coreMLNLModel
        )
        XCTAssertEqual(display, .label("Needs review"))
    }

    func testCalibratedNilConfidenceReturnsHidden() {
        let display = policy.displayLabel(
            confidence: nil, confidenceKind: .calibratedProbability, source: .coreMLNLModel
        )
        XCTAssertEqual(display, .hidden)
    }

    // MARK: - uncalibratedScore

    func testUncalibratedScoreUserCorrectionShowsLearnedLabel() {
        let display = policy.displayLabel(
            confidence: 0.9, confidenceKind: .uncalibratedScore, source: .userCorrection
        )
        XCTAssertEqual(display, .label("Learned from your corrections"))
    }

    func testUncalibratedScoreKNNShowsAutoCategorized() {
        let display = policy.displayLabel(
            confidence: 0.78, confidenceKind: .uncalibratedScore, source: .personalizedKNN
        )
        XCTAssertEqual(display, .label("Auto-categorized"))
    }

    func testUncalibratedScoreFallbackShowsNeedsReview() {
        let display = policy.displayLabel(
            confidence: 0.3, confidenceKind: .uncalibratedScore, source: .fallbackRule
        )
        XCTAssertEqual(display, .label("Needs review"))
    }

    // MARK: - heuristicOrdinal

    func testHeuristicOrdinalNeverShowsNumber() {
        let display = policy.displayLabel(confidence: 0.88, confidenceKind: .heuristicOrdinal, source: .personalizedKNN)
        XCTAssertEqual(display, .label("Auto-categorized"))
        if case let .label(text) = display {
            XCTAssertFalse(text.contains("%"), "Heuristic ordinal must never show numeric confidence")
        }
    }

    // MARK: - notApplicable

    func testNotApplicableReturnsHidden() {
        let display = policy.displayLabel(confidence: 0.3, confidenceKind: .notApplicable, source: .fallbackRule)
        XCTAssertEqual(display, .hidden)
    }

    // MARK: - rawScore (domain models without provenance)

    func testRawScoreAlwaysHidden() {
        XCTAssertEqual(policy.displayLabel(rawScore: 0.0), .hidden)
        XCTAssertEqual(policy.displayLabel(rawScore: 0.5), .hidden)
        XCTAssertEqual(policy.displayLabel(rawScore: 0.99), .hidden)
    }
}

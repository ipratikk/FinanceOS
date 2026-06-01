import Foundation

// MARK: - ConfidenceDisplay

/// The resolved user-facing representation of a confidence value.
public enum ConfidenceDisplay: Equatable, Sendable {
    /// Show a qualitative label string.
    case label(String)
    /// Do not show any confidence indicator.
    case hidden
}

// MARK: - ConfidenceDisplayPolicy

/// Translates raw confidence values and their provenance into safe UI representations.
///
/// Raw `Double` confidence values must never appear in user-facing UI unless
/// `confidenceKind == .calibratedProbability`. All other kinds map to qualitative
/// labels or are suppressed entirely.
public struct ConfidenceDisplayPolicy: Sendable {
    public init() {}

    /// Resolves how to display confidence for a `CategoryPrediction` (has full provenance).
    public func displayLabel(
        confidence: Double?,
        confidenceKind: ConfidenceKind,
        source: IntelligenceSource
    ) -> ConfidenceDisplay {
        switch confidenceKind {
        case .deterministic:
            return .label("Matched a known bank pattern")
        case .calibratedProbability:
            guard let confidence else { return .hidden }
            return calibratedDisplay(confidence)
        case .uncalibratedScore, .heuristicOrdinal:
            return sourceLabel(source)
        case .notApplicable:
            return .hidden
        }
    }

    /// Resolves display for domain scores without `ConfidenceKind` provenance.
    ///
    /// Recurring pattern confidence, relationship confidence, and insight confidence
    /// are all heuristic scores — suppress numeric display entirely.
    public func displayLabel(rawScore _: Double) -> ConfidenceDisplay {
        .hidden
    }

    // MARK: - Private

    private func calibratedDisplay(_ confidence: Double) -> ConfidenceDisplay {
        switch confidence {
        case 0.9...: return .label("\(Int(confidence * 100))%")
        case 0.7 ..< 0.9: return .label("\(Int(confidence * 100))%")
        case 0.5 ..< 0.7: return .label("Moderate confidence")
        default: return .label("Needs review")
        }
    }

    private func sourceLabel(_ source: IntelligenceSource) -> ConfidenceDisplay {
        switch source {
        case .userCorrection: return .label("Learned from your corrections")
        case .structuralRule: return .label("Matched a known bank pattern")
        case .personalizedKNN, .coreMLNLModel: return .label("Auto-categorized")
        case .fallbackRule: return .label("Needs review")
        case .manual: return .label("Manually set")
        }
    }
}

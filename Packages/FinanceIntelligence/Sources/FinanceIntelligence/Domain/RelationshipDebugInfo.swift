import Foundation

public struct RelationshipEvidence: Codable, Equatable, Sendable {
    public let code: String
    public let value: String
    public let weight: Double?

    public init(code: String, value: String, weight: Double? = nil) {
        self.code = code
        self.value = value
        self.weight = weight
    }
}

public struct RelationshipDebugInfo: Codable, Equatable, Sendable {
    public let personId: String
    public let candidateType: RelationshipType
    public let confidence: Double
    public let confidenceKind: ConfidenceKind
    public let evidence: [RelationshipEvidence]
    public let excludedByRules: [String]
    public let configVersion: String

    public init(
        personId: String,
        candidateType: RelationshipType,
        confidence: Double,
        confidenceKind: ConfidenceKind,
        evidence: [RelationshipEvidence],
        excludedByRules: [String],
        configVersion: String
    ) {
        self.personId = personId
        self.candidateType = candidateType
        self.confidence = confidence
        self.confidenceKind = confidenceKind
        self.evidence = evidence
        self.excludedByRules = excludedByRules
        self.configVersion = configVersion
    }
}

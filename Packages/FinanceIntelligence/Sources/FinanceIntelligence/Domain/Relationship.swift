import Foundation

public enum RelationshipVerificationState: String, Codable, Sendable, CaseIterable {
    case inferred
    case userConfirmed
    case userRejected
    case userCorrected
}

public enum RelationshipType: String, Codable, Sendable, CaseIterable {
    case landlord
    case tenant
    case friend
    case family
    case employer
    case employee
    case loanProvider = "loan_provider"
    case loanRecipient = "loan_recipient"
    case reimbursement
    case unknown
}

public enum RelationshipSignal: String, Codable, Sendable, CaseIterable {
    case recurringAmount // consistent amount month-to-month
    case postSalaryTiming // payment occurs shortly after salary credit
    case roundNumber // amount divisible by 500 or 1000
    case regularInterval // consistent date pattern
    case upiLabel // UPI label contains keywords (rent, owner, sir)
    case historicalPattern // corroborated by transaction history
}

public struct Relationship: Identifiable, Sendable, Codable {
    public let id: UUID
    public let fromPersonId: String?
    public let toPersonId: String?
    public let type: RelationshipType
    public var confidence: Double
    public var evidenceCount: Int
    public var signals: [RelationshipSignal]
    public let createdAt: Date
    public var updatedAt: Date
    public var verificationState: RelationshipVerificationState

    public init(
        id: UUID = UUID(),
        fromPersonId: String? = nil,
        toPersonId: String?,
        type: RelationshipType,
        confidence: Double,
        evidenceCount: Int = 1,
        signals: [RelationshipSignal] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        verificationState: RelationshipVerificationState = .inferred
    ) {
        self.id = id
        self.fromPersonId = fromPersonId
        self.toPersonId = toPersonId
        self.type = type
        self.confidence = confidence
        self.evidenceCount = evidenceCount
        self.signals = signals
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.verificationState = verificationState
    }
}

public extension RelationshipType {
    func displayLabel(verificationState: RelationshipVerificationState) -> String {
        if verificationState == .userConfirmed {
            return rawValue.replacingOccurrences(of: "_", with: " ").capitalized
        }
        switch self {
        case .landlord: return "Likely landlord"
        case .employer: return "Likely salary source"
        case .friend: return "Frequent transfer contact"
        case .family: return "Possible family"
        default: return rawValue.replacingOccurrences(of: "_", with: " ").capitalized
        }
    }
}

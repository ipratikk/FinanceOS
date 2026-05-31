import Foundation

public enum RelationshipType: String, Codable, Sendable, CaseIterable {
    case landlord      = "landlord"
    case tenant        = "tenant"
    case friend        = "friend"
    case family        = "family"
    case employer      = "employer"
    case employee      = "employee"
    case loanProvider  = "loan_provider"
    case loanRecipient = "loan_recipient"
    case reimbursement = "reimbursement"
    case unknown       = "unknown"
}

public enum RelationshipSignal: String, Codable, Sendable, CaseIterable {
    case recurringAmount   // consistent amount month-to-month
    case postSalaryTiming  // payment occurs shortly after salary credit
    case roundNumber       // amount divisible by 500 or 1000
    case regularInterval   // consistent date pattern
    case upiLabel          // UPI label contains keywords (rent, owner, sir)
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

    public init(
        id: UUID = UUID(),
        fromPersonId: String? = nil,
        toPersonId: String?,
        type: RelationshipType,
        confidence: Double,
        evidenceCount: Int = 1,
        signals: [RelationshipSignal] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date()
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
    }
}

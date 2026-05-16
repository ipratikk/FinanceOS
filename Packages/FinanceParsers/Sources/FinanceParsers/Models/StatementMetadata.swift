import Foundation

public struct StatementMetadata: Codable, Sendable, Equatable {
    public let customerName: String?
    public let customerId: String?
    public let accountNumber: String?
    public let fullAccountNumber: String?
    public let accountType: String?
    public let cardType: String?
    public let branch: String?
    public let branchCode: String?
    public let address: String?
    public let email: String?
    public let phone: String?
    public let ifsc: String?
    public let micr: String?
    public let openingBalance: Int64?
    public let closingBalance: Int64?
    public let debitCount: Int?
    public let creditCount: Int?
    public let generatedAt: Date?

    public init(
        customerName: String? = nil,
        customerId: String? = nil,
        accountNumber: String? = nil,
        fullAccountNumber: String? = nil,
        accountType: String? = nil,
        cardType: String? = nil,
        branch: String? = nil,
        branchCode: String? = nil,
        address: String? = nil,
        email: String? = nil,
        phone: String? = nil,
        ifsc: String? = nil,
        micr: String? = nil,
        openingBalance: Int64? = nil,
        closingBalance: Int64? = nil,
        debitCount: Int? = nil,
        creditCount: Int? = nil,
        generatedAt: Date? = nil
    ) {
        self.customerName = customerName
        self.customerId = customerId
        self.accountNumber = accountNumber
        self.fullAccountNumber = fullAccountNumber
        self.accountType = accountType
        self.cardType = cardType
        self.branch = branch
        self.branchCode = branchCode
        self.address = address
        self.email = email
        self.phone = phone
        self.ifsc = ifsc
        self.micr = micr
        self.openingBalance = openingBalance
        self.closingBalance = closingBalance
        self.debitCount = debitCount
        self.creditCount = creditCount
        self.generatedAt = generatedAt
    }
}

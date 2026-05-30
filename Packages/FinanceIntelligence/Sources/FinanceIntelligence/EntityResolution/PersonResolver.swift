import Foundation

/// How a `PersonResolverResult` was extracted.
public enum PersonResolutionSource: String, Sendable, Codable, CaseIterable {
    case upi    // "UPI-NAME-vpa@bank-..." format
    case neft   // "NEFT CR/DR-BANK-NAME-REF" format
    case imps   // "IMPS-TXNID-NAME-BANK" format
}

/// The result of resolving a person entity from a bank description.
public struct PersonResolverResult: Sendable {
    /// Title-cased canonical name extracted from the description.
    public let name: String
    /// UPI virtual payment address (only for UPI-format descriptions).
    public let upiHandle: String?
    /// Resolution confidence: UPI 0.90, NEFT 0.80, IMPS 0.75.
    public let confidence: Double
    /// Which format was parsed.
    public let source: PersonResolutionSource

    public init(name: String, upiHandle: String?, confidence: Double, source: PersonResolutionSource) {
        self.name = name
        self.upiHandle = upiHandle
        self.confidence = confidence
        self.source = source
    }
}

/// Extracts person entities from UPI/NEFT/IMPS bank description strings.
///
/// Returns nil for merchant payments, non-structured descriptions, or
/// descriptions that resolve to business entities rather than individuals.
public struct PersonResolver: Sendable {
    public init() {}

    /// Attempts to resolve a person from `rawDescription`.
    /// Returns nil when the description is not a person-to-person transfer.
    public func resolve(_ rawDescription: String) -> PersonResolverResult? {
        guard let parsed = UPIDescriptionParser.parse(rawDescription) else { return nil }
        guard parsed.isPersonTransfer && !parsed.isMerchantPayment else { return nil }
        guard !parsed.merchantName.trimmingCharacters(in: .whitespaces).isEmpty else { return nil }

        let source = detectedSource(rawDescription)
        let confidence: Double
        switch source {
        case .upi:  confidence = 0.90
        case .neft: confidence = 0.80
        case .imps: confidence = 0.75
        }

        return PersonResolverResult(
            name: titleCase(parsed.merchantName),
            upiHandle: parsed.vpa,
            confidence: confidence,
            source: source
        )
    }
}

// MARK: - Private Helpers

private extension PersonResolver {
    func detectedSource(_ raw: String) -> PersonResolutionSource {
        let upper = raw.uppercased()
        if upper.hasPrefix("UPI-") { return .upi }
        if upper.hasPrefix("NEFT") { return .neft }
        return .imps
    }

    func titleCase(_ input: String) -> String {
        input
            .components(separatedBy: " ")
            .map { word in
                guard !word.isEmpty else { return word }
                return word.prefix(1).uppercased() + word.dropFirst().lowercased()
            }
            .joined(separator: " ")
    }
}

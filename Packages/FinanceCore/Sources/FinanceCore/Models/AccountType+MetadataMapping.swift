import Foundation

public extension AccountType {
    static func from(metadataAccountType: String) -> AccountType {
        let normalized = metadataAccountType.lowercased().trimmingCharacters(in: .whitespaces)

        switch normalized {
        case "current":
            return .current
        case "savings", "ppf", "money market", "":
            return .savings
        default:
            return .savings
        }
    }
}

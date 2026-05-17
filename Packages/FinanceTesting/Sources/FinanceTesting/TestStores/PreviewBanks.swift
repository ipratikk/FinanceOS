import FinanceCore
import Foundation

/// Preview/test data for banks.
public enum PreviewBanks {
    public static let bankId = UUID(uuidString: "00000000-0000-0000-0000-000000000099")!

    public static func chase() -> Bank {
        Bank(id: bankId, name: "Chase", providerType: .bank)
    }

    public static func amex() -> Bank {
        Bank(
            id: UUID(uuidString: "00000000-0000-0000-0000-0000000000A1")!,
            name: "American Express",
            providerType: .credit
        )
    }

    public static var all: [Bank] {
        [chase(), amex()]
    }
}

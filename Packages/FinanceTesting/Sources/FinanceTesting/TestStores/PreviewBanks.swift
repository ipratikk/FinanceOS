import FinanceCore
import Foundation

/// Preview/test data for banks.
public enum PreviewBanks {
    public static let hdfcId = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
    public static let amexId = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!

    public static func hdfc() -> Bank {
        Bank(id: hdfcId, bank: .hdfc)
    }

    public static func amex() -> Bank {
        Bank(id: amexId, bank: .amex)
    }

    public static var all: [Bank] {
        [hdfc(), amex()]
    }
}

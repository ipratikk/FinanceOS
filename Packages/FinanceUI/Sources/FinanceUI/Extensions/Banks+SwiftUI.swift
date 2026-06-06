import FinanceCore
import SwiftUI

public extension Banks {
    var tintColor: Color {
        switch self {
        case .hdfc: return Color(red: 0.0, green: 0.298, blue: 0.592)
        case .icici: return Color(red: 0.969, green: 0.58, blue: 0.0)
        case .amex: return Color(red: 0.0, green: 0.471, blue: 0.753)
        case .scapia: return Color(red: 1.0, green: 0.42, blue: 0.21)
        }
    }
}

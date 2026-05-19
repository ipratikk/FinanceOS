import SwiftUI

extension Divider {
    /// Semantic divider with standard opacity for FinanceOS.
    /// Replaces hardcoded .opacity(0.3) calls throughout codebase.
    func semantic() -> some View {
        opacity(0.3)
    }
}

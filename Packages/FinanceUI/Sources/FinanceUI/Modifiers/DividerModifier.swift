import SwiftUI

/// Semantic opacity helpers on `Divider` for FinanceOS.
extension Divider {
    /// Applies the standard 30% opacity used for all dividers in FinanceOS.
    ///
    /// Replaces scattered `.opacity(0.3)` calls — update the token here to restyle globally.
    func semantic() -> some View {
        opacity(0.3)
    }
}

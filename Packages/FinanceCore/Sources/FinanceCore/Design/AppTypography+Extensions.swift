import SwiftUI

// MARK: - Specialized Typography Extensions

public extension View {
    /// Applies the 52pt semibold hero font used for the dashboard net-flow amount.
    func netHeroAmount() -> some View {
        font(AppTypography.netHeroAmount)
    }

    /// Applies 12pt monospaced regular for masked account number strings (e.g. "•••• 1234").
    func maskedAccount() -> some View {
        font(AppTypography.maskedAccount)
    }
}

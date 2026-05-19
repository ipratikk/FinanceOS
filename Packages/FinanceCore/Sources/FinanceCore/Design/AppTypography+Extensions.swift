import SwiftUI

// MARK: - Specialized Typography Extensions

public extension View {
    func netHeroAmount() -> some View {
        font(AppTypography.netHeroAmount)
    }

    func maskedAccount() -> some View {
        font(AppTypography.maskedAccount)
    }
}

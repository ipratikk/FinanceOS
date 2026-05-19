import FinanceCore
import SwiftUI

// MARK: - Wallpaper

/// Flat background for the app root.
/// Simple dark color with minimal accent tint.
public struct Wallpaper: View {
    public init() {}

    public var body: some View {
        ZStack {
            AppColors.base

            RadialGradient(
                colors: [AppColors.accent.opacity(0.02), .clear],
                center: .init(x: 0.88, y: 0.88),
                startRadius: 0,
                endRadius: 500
            )
        }
        .ignoresSafeArea()
    }
}

#Preview {
    Wallpaper()
}

import SwiftUI

// MARK: - Wallpaper

/// Liquid Glass wallpaper background for the app root.
/// Sits behind NavigationSplitView, providing a subtle near-monochrome
/// radial gradient that glass surfaces refract.
public struct Wallpaper: View {
    public init() {}

    public var body: some View {
        ZStack {
            Color(red: 0.039, green: 0.047, blue: 0.067)

            RadialGradient(
                colors: [Color.white.opacity(0.025), .clear],
                center: .init(x: 0.18, y: 0.12),
                startRadius: 0,
                endRadius: 600
            )

            RadialGradient(
                colors: [Color(red: 1.0, green: 0.62, blue: 0.04).opacity(0.04), .clear],
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

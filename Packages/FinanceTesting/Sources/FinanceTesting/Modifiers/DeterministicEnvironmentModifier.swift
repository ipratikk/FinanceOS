import SwiftUI

/// Applies deterministic environment settings for snapshot testing.
/// Ensures consistent rendering across snapshot runs.
public struct DeterministicEnvironmentModifier: ViewModifier {
    public let colorScheme: ColorScheme

    public func body(content: Content) -> some View {
        content
            .environment(\.timeZone, SnapshotConfiguration.timeZone)
            .environment(\.locale, SnapshotConfiguration.locale)
            .environment(\.colorScheme, colorScheme)
            .preferredColorScheme(colorScheme)
    }
}

public extension View {
    /// Apply deterministic environment settings for snapshot testing.
    func snapshotEnvironment(colorScheme: ColorScheme = .light) -> some View {
        modifier(DeterministicEnvironmentModifier(colorScheme: colorScheme))
    }
}

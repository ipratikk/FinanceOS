import SwiftUI

/// Applies deterministic environment settings for snapshot testing.
/// Ensures consistent rendering across snapshot runs.
public struct DeterministicEnvironmentModifier: ViewModifier {
    public let configuration: SnapshotConfiguration

    public func body(content: Content) -> some View {
        content
            .environment(\.timeZone, configuration.timeZone)
            .environment(\.locale, configuration.locale)
            .environment(\.colorScheme, configuration.useLightColorScheme ? .light : .dark)
            .preferredColorScheme(configuration.useLightColorScheme ? .light : .dark)
    }
}

public extension View {
    /// Apply deterministic environment settings for snapshot testing.
    func snapshotEnvironment(_ configuration: SnapshotConfiguration = .default) -> some View {
        modifier(DeterministicEnvironmentModifier(configuration: configuration))
    }
}

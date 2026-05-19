import SwiftUI

/// Applies theme settings for snapshot testing (light/dark mode).
public struct ThemeSnapshotModifier: ViewModifier {
    public let theme: SnapshotTheme

    public func body(content: Content) -> some View {
        content
            .preferredColorScheme(theme.colorScheme)
    }
}

/// Size variant for snapshot testing.
public enum SnapshotSizeVariant {
    case compact
    case regular
    case expanded

    public var width: CGFloat {
        switch self {
        case .compact:
            375
        case .regular:
            390
        case .expanded:
            430
        }
    }

    public var displayName: String {
        switch self {
        case .compact:
            "compact"
        case .regular:
            "regular"
        case .expanded:
            "expanded"
        }
    }
}

public extension View {
    /// Apply theme settings for snapshot testing.
    func snapshotTheme(_ theme: SnapshotTheme = .light) -> some View {
        modifier(ThemeSnapshotModifier(theme: theme))
    }

    /// Frame the view for a specific size variant.
    func snapshotSize(_ variant: SnapshotSizeVariant = .regular) -> some View {
        frame(width: variant.width)
    }
}

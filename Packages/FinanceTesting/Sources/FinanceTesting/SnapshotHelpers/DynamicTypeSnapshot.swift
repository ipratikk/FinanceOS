import SwiftUI

/// Dynamic type sizes for accessibility snapshot testing.
public enum DynamicTypeSize: CaseIterable {
    case extraSmall
    case small
    case medium
    case large
    case extraLarge
    case extraExtraLarge
    case extraExtraExtraLarge
    case accessibility1
    case accessibility2
    case accessibility3

    public var swiftUIValue: SwiftUI.DynamicTypeSize {
        switch self {
        case .extraSmall:
            .xSmall
        case .small:
            .small
        case .medium:
            .medium
        case .large:
            .large
        case .extraLarge:
            .xLarge
        case .extraExtraLarge:
            .xxLarge
        case .extraExtraExtraLarge:
            .xxxLarge
        case .accessibility1:
            .accessibility1
        case .accessibility2:
            .accessibility2
        case .accessibility3:
            .accessibility3
        }
    }

    public var displayName: String {
        switch self {
        case .extraSmall:
            "xs"
        case .small:
            "s"
        case .medium:
            "m"
        case .large:
            "l"
        case .extraLarge:
            "xl"
        case .extraExtraLarge:
            "xxl"
        case .extraExtraExtraLarge:
            "xxxl"
        case .accessibility1:
            "a1"
        case .accessibility2:
            "a2"
        case .accessibility3:
            "a3"
        }
    }

    /// Common size for snapshot testing (medium).
    public static let defaultSize: DynamicTypeSize = .medium

    /// Small and large sizes for regression testing.
    public static let testSizes: [DynamicTypeSize] = [
        .small,
        .medium,
        .large,
        .extraLarge
    ]
}

public extension View {
    /// Apply dynamic type size for snapshot testing.
    func snapshotDynamicType(_ size: DynamicTypeSize = .medium) -> some View {
        environment(\.dynamicTypeSize, size.swiftUIValue)
    }
}

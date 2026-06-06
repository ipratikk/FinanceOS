import SwiftUI

public struct FDSScale: Equatable, Sendable {
    public let typography: CGFloat
    public let spacing: CGFloat
    public let breakpoint: FDSBreakpoint

    public static let `default` = FDSScale(
        typography: 1.0,
        spacing: 1.0,
        breakpoint: .regular
    )
}

public extension EnvironmentValues {
    @Entry var fdsScale: FDSScale = FDSScale.default
}

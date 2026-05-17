import SwiftUI

// MARK: - Shadow Definition

public struct AppShadow: Sendable {
    public let color: Color
    public let radius: CGFloat
    public let y: CGFloat

    public init(color: Color, radius: CGFloat, y: CGFloat) {
        self.color = color
        self.radius = radius
        self.y = y
    }
}

// MARK: - Predefined Shadows

public extension AppShadow {
    static let subtle = AppShadow(color: .black.opacity(0.12), radius: 4, y: 1)
    static let card = AppShadow(color: .black.opacity(0.20), radius: 10, y: 3)
    static let float = AppShadow(color: .black.opacity(0.30), radius: 20, y: 6)
    static let modal = AppShadow(color: .black.opacity(0.45), radius: 40, y: 12)

    // Legacy accessors for backward compatibility during Phase 1
    static let subtleRadius: CGFloat = 4
    static let cardRadius: CGFloat = 10
    static let floatRadius: CGFloat = 20
    static let modalRadius: CGFloat = 40

    static let subtleOpacity: Double = 0.12
    static let cardOpacity: Double = 0.20
    static let floatOpacity: Double = 0.30
    static let modalOpacity: Double = 0.45
}

import SwiftUI

/// Semantic opacity and color constants for FinanceOS.
/// All opacity values and border colors must use these.
public extension AppColors {
    // MARK: - Semantic Opacity Values

    static let dividerDefault = Color.white.opacity(0.06)
    static let borderDefault = Color.white.opacity(0.12)
    static let overlayLight = Color.white.opacity(0.03)
    static let overlayMedium = Color.white.opacity(0.05)

    // MARK: - Semantic Opacity Variants

    static let accentLight = accent.opacity(0.07)
    static let accentMedium = accent.opacity(0.15)
    static let accentDark = accent.opacity(0.5)

    static let debitLight = debit.opacity(0.12)
    static let creditLight = credit.opacity(0.12)

    // MARK: - Skeleton / Loading States

    static let skeletonLight = Color.white.opacity(0.04)
    static let skeletonMedium = Color.white.opacity(0.08)

    // MARK: - Card Network Colors (Centralized)

    enum CardNetwork {
        public static let visa = Color(red: 0.13, green: 0.39, blue: 0.73)
        public static let mastercard = Color(red: 0.99, green: 0.49, blue: 0.00)
        public static let amex = Color(red: 0.00, green: 0.47, blue: 0.73)
        public static let rupay = Color(red: 0.00, green: 0.35, blue: 0.62)
        public static let other = Color.secondary
    }

    // MARK: - Avatar Tints (Deterministic)

    enum AvatarTint {
        public static let tint1 = Color(hue: 0.0, saturation: 0.85, brightness: 0.90) // Red
        public static let tint2 = Color(hue: 0.08, saturation: 0.90, brightness: 0.95) // Orange
        public static let tint3 = Color(hue: 0.15, saturation: 0.85, brightness: 0.95) // Yellow
        public static let tint4 = Color(hue: 0.35, saturation: 0.80, brightness: 0.90) // Green
        public static let tint5 = Color(hue: 0.55, saturation: 0.70, brightness: 0.95) // Cyan
        public static let tint6 = Color(hue: 0.65, saturation: 0.80, brightness: 0.90) // Blue
        public static let tint7 = Color(hue: 0.80, saturation: 0.75, brightness: 0.90) // Purple

        public static func deterministic(for seed: String) -> Color {
            let hash = seed.hashValue
            let tints: [Color] = [tint1, tint2, tint3, tint4, tint5, tint6, tint7]
            let index = abs(hash) % tints.count
            return tints[index]
        }
    }
}

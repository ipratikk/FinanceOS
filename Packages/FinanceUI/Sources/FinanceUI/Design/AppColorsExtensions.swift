import SwiftUI

/// Semantic opacity and color constants for FinanceOS.
/// All opacity values and border colors must use these.
public extension AppColors {
    // MARK: - Semantic Opacity Values

    /// 6% white — default horizontal rule / list divider.
    static let dividerDefault = textPrimary.opacity(0.06)
    /// 12% white — default container border (stronger than divider).
    static let borderDefault = textPrimary.opacity(0.12)
    /// 3% white — ultra-subtle overlay wash (modal scrims, hover states).
    static let overlayLight = textPrimary.opacity(0.03)
    /// 5% white — medium overlay for sheet backgrounds.
    static let overlayMedium = textPrimary.opacity(0.05)

    // MARK: - Semantic Opacity Variants

    /// 7% accent — very subtle accent tint for selected row backgrounds.
    static let accentLight = accent.opacity(0.07)
    /// 15% accent — accent tint for chips, badges, and focus rings.
    static let accentMedium = accent.opacity(0.15)
    /// 50% accent — stronger accent fill for progress bars and indicators.
    static let accentDark = accent.opacity(0.5)

    /// 12% danger red — soft background tint for debit amount chips.
    static let debitLight = debit.opacity(0.12)
    /// 12% success green — soft background tint for credit amount chips.
    static let creditLight = credit.opacity(0.12)

    // MARK: - Skeleton / Loading States

    /// 4% white — base skeleton shimmer color.
    static let skeletonLight = textPrimary.opacity(0.04)
    /// 8% white — highlight band of skeleton shimmer animation.
    static let skeletonMedium = textPrimary.opacity(0.08)

    // MARK: - Card Network Colors (Centralized)

    /// Brand colors for each payment network, used on card-art and network badges.
    enum CardNetwork {
        public static let visa = Color(red: 0.13, green: 0.39, blue: 0.73)
        public static let mastercard = Color(red: 0.99, green: 0.49, blue: 0.00)
        public static let amex = Color(red: 0.00, green: 0.47, blue: 0.73)
        public static let rupay = Color(red: 0.00, green: 0.35, blue: 0.62)
        public static let other = Color.secondary
    }

    // MARK: - Avatar Tints (Deterministic)

    /// Seven hue-spaced tints used for bank/account avatar icons.
    /// `deterministic(for:)` maps any string seed to a stable, reproducible tint.
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

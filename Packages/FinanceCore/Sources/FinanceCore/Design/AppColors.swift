import SwiftUI

public enum AppColors {
    // MARK: - Backgrounds

    public static let base = Color(red: 0.06, green: 0.06, blue: 0.07) // #0f0f12 — main background
    public static let surface = Color(red: 0.12, green: 0.12, blue: 0.13) // #1e1e21 — primary surface
    public static let surface2 = Color(red: 0.16, green: 0.16, blue: 0.17) // #292a2b — elevated surface
    public static let surface3 = Color(red: 0.20, green: 0.20, blue: 0.22) // #333537 — top elevation
    public static let elevated = surface2

    // MARK: - Borders & Dividers

    public static let border = Color.white.opacity(0.08) // subtle border
    public static let borderAccent = Color.white.opacity(0.12) // accent border
    public static let borderSubtle = Color.white.opacity(0.05) // minimal separator

    // MARK: - Glass & Material overlays (deprecated — use border colors instead)

    public static let glass = Color.white.opacity(0.02) // minimal tint
    public static let borderGlass = Color.white.opacity(0.08) // flat border

    // MARK: - Primary Accents

    public static let accentGreen = Color(red: 0.204, green: 0.784, blue: 0.349) // #34C759 — Primary accent
    public static let accentBlue = Color(red: 0.039, green: 0.518, blue: 1.0) // #0A84FF — Secondary accent
    public static let accentPurple = Color(red: 0.369, green: 0.361, blue: 0.902) // #5E5CE6 — Tertiary accent
    public static let accentGold = accentGreen // Mapped for compatibility
    public static let accentSlate = accentGreen // Mapped for compatibility
    public static let accentIce = accentBlue // Mapped for compatibility
    public static let accentMuted = Color(red: 0.557, green: 0.557, blue: 0.576) // #8E8E93 — muted gray

    // MARK: - Semantic Colors

    public static let accent = accentGreen // Default primary accent — bright green
    public static let success = accentGreen // Positive transaction
    public static let danger = Color(red: 1.0, green: 0.231, blue: 0.188) // #FF3B30 — Apple Red
    public static let info = accentBlue // Informational color
    public static let warning = Color(red: 1.0, green: 0.584, blue: 0) // #FF9500 — Apple Orange

    // MARK: - Legacy semantic colors (mapped for backwards compatibility)

    public static let credit = success // Positive transaction
    public static let debit = danger // Negative transaction
    public static let purple = accentPurple // Fallback color

    // MARK: - Deprecated neon colors (removed for classy aesthetic)

    public static let accentCyan = accentBlue // Replaced
    public static let accentBlueDeprecated = accentBlue // Replaced
    public static let accentPurpleDeprecated = accentPurple // Replaced
    public static let accentPink = danger // Replaced
    public static let accentLime = success // Replaced
    public static let accentOrange = warning // Replaced

    // MARK: - Text (Apple System)

    public static let textPrimary = Color.white // #FFFFFF
    public static let textSecondary = Color(red: 0.631, green: 0.631, blue: 0.651) // #A1A1A6
    public static let textTertiary = Color(red: 0.557, green: 0.557, blue: 0.576) // #8E8E93
    public static let textDisabled = Color(red: 0.322, green: 0.322, blue: 0.361) // #52525B
}

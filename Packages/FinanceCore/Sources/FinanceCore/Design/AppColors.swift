import SwiftUI

public enum AppColors {
    // MARK: - Backgrounds

    public static let base = Color(red: 0.06, green: 0.06, blue: 0.07) // #0f0f12 — main background
    public static let surface = Color(red: 0.12, green: 0.12, blue: 0.13) // #1e1e21 — primary surface
    public static let surface2 = Color(red: 0.16, green: 0.16, blue: 0.17) // #292a2b — elevated surface
    public static let surface3 = Color(red: 0.20, green: 0.20, blue: 0.22) // #333537 — top elevation
    public static let elevated = surface2

    // MARK: - Borders & Dividers
    public static let border = textPrimary.opacity(0.08) // subtle border
    public static let borderAccent = textPrimary.opacity(0.12) // accent border
    public static let borderSubtle = textPrimary.opacity(0.05) // minimal separator

    // MARK: - Glass & Material overlays (deprecated — use border colors instead)

    public static let glass = textPrimary.opacity(0.02) // minimal tint
    public static let borderGlass = textPrimary.opacity(0.08) // flat border

    // MARK: - Primary Accents (Apple System Colors)

    public static let accentGreen = Color(red: 0.188, green: 0.827, blue: 0.345) // #30D158 — Emerald (primary)
    public static let accentOrange = Color(red: 1.0, green: 0.62, blue: 0.04) // #FF9F0A — Gold (secondary)
    public static let accentBlue = Color(red: 0.039, green: 0.518, blue: 1.0) // #0A84FF — Cobalt
    public static let accentPurple = Color(red: 0.749, green: 0.345, blue: 0.949) // #BF5AF2 — Plum
    public static let accentGold = accentOrange // Mapped for compatibility
    public static let accentSlate = accentBlue // Mapped for compatibility
    public static let accentIce = accentBlue // Mapped for compatibility
    public static let accentMuted = Color(red: 0.557, green: 0.557, blue: 0.576) // #8E8E93 — muted gray

    // MARK: - Semantic Colors (Apple System)

    public static let accent = accentGreen // Default primary accent — emerald green
    public static let success = Color(red: 0.188, green: 0.827, blue: 0.345) // #30D158 — Apple Green
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

    // MARK: - Text (Apple System)
    public static let textPrimary = Color.white // #FFFFFF
    public static let textSecondary = Color(red: 0.631, green: 0.631, blue: 0.651) // #A1A1A6
    public static let textTertiary = Color(red: 0.557, green: 0.557, blue: 0.576) // #8E8E93
    public static let textDisabled = Color(red: 0.322, green: 0.322, blue: 0.361) // #52525B
    public static let clear = Color.clear
}

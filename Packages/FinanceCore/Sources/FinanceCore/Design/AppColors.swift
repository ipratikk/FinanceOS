import SwiftUI

public enum AppColors {
    // MARK: - Backgrounds (Apple System Dark Mode)

    public static let base = Color(red: 0, green: 0, blue: 0) // #000000 — pure black
    public static let surface = Color(red: 0.110, green: 0.110, blue: 0.114) // #1C1C1E — primary surface
    public static let surface2 = Color(red: 0.173, green: 0.173, blue: 0.180) // #2C2C2E — elevated surface
    public static let surface3 = Color(red: 0.227, green: 0.227, blue: 0.235) // #3A3A3C — top elevation
    public static let elevated = surface2

    // MARK: - Glass & Material overlays

    public static let glass = Color.white.opacity(0.06) // subtle tint for glass backgrounds
    public static let borderGlass = Color.white.opacity(0.15) // glass panel border stroke
    public static let borderSubtle = Color.white.opacity(0.06) // separator on glass

    // MARK: - Borders

    public static let border = Color.white.opacity(0.1) // primary border
    public static let borderAccent = Color.white.opacity(0.15) // accent border

    // MARK: - Primary Accents (Apple System Colors)

    public static let accentBlue = Color(red: 0.039, green: 0.518, blue: 1.0) // #0A84FF — SF Blue primary
    public static let accentPurple = Color(red: 0.369, green: 0.361, blue: 0.902) // #5E5CE6 — iOS Purple secondary
    public static let accentGold = accentBlue // Mapped for compatibility
    public static let accentSlate = accentBlue // Mapped for compatibility
    public static let accentIce = accentBlue // Mapped for compatibility
    public static let accentMuted = Color(red: 0.557, green: 0.557, blue: 0.576) // #8E8E93 — muted gray

    // MARK: - Semantic Colors (Apple System)

    public static let accent = accentBlue // Default primary accent
    public static let success = Color(red: 0.204, green: 0.784, blue: 0.349) // #34C759 — Apple Green
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

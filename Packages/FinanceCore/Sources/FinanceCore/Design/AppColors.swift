import SwiftUI

public enum AppColors {
    // MARK: - Backgrounds (elevation layers)

    public static let base = Color(red: 0.051, green: 0.051, blue: 0.059) // #0D0D0F
    public static let surface = Color(red: 0.086, green: 0.086, blue: 0.098) // #161618
    public static let surface2 = Color(red: 0.110, green: 0.110, blue: 0.122) // #1C1C1F
    public static let surface3 = Color(red: 0.141, green: 0.141, blue: 0.157) // #242428
    public static let elevated = Color(red: 0.118, green: 0.118, blue: 0.133) // #1E1E22 — use inside material panels

    // MARK: - Glass & Material overlays

    public static let glass = Color.white.opacity(0.04) // subtle tint for glass backgrounds
    public static let borderGlass = Color.white.opacity(0.12) // glass panel border stroke
    public static let borderSubtle = Color.white.opacity(0.06) // separator on glass

    // MARK: - Borders

    public static let border = Color(red: 0.165, green: 0.165, blue: 0.180) // #2A2A2E
    public static let borderAccent = Color(red: 0.227, green: 0.227, blue: 0.251) // #3A3A40

    // MARK: - Primary Accents (refined luxury fintech)

    public static let accentGold = Color(red: 0.749, green: 0.616, blue: 0.341) // #BF9D57 — primary action, luxury
    public static let accentSlate = Color(red: 0.431, green: 0.498, blue: 0.616) // #6E7F9D — secondary, professional
    public static let accentIce = Color(red: 0.635, green: 0.816, blue: 0.886) // #A2D0E2 — data, clean
    public static let accentMuted = Color(red: 0.451, green: 0.451, blue: 0.498) // #73737F — tertiary, subtle

    // MARK: - Semantic Colors (refined, not bright)

    public static let accent = accentGold // Default primary accent
    public static let success = Color(red: 0.384, green: 0.671, blue: 0.522) // #62AB85 — positive, muted green
    public static let danger = Color(red: 0.761, green: 0.408, blue: 0.373) // #C26A5F — destructive, warm red
    public static let info = accentSlate // Informational color
    public static let warning = Color(red: 0.796, green: 0.604, blue: 0.325) // #CB9A53 — caution, warm tone

    // MARK: - Legacy semantic colors (mapped for backwards compatibility)

    public static let credit = success // Positive transaction
    public static let debit = danger // Negative transaction
    public static let purple = accentSlate // Fallback color

    // MARK: - Deprecated neon colors (removed for classy aesthetic)

    public static let accentCyan = accentIce // Replaced
    public static let accentBlue = accentSlate // Replaced
    public static let accentPurple = accentMuted // Replaced
    public static let accentPink = danger // Replaced
    public static let accentLime = success // Replaced
    public static let accentOrange = warning // Replaced

    // MARK: - Text

    public static let textPrimary = Color.white
    public static let textSecondary = Color(red: 0.631, green: 0.631, blue: 0.667) // #A1A1AA
    public static let textTertiary = Color(red: 0.447, green: 0.447, blue: 0.478) // #71717A
    public static let textDisabled = Color(red: 0.322, green: 0.322, blue: 0.361) // #52525B
}

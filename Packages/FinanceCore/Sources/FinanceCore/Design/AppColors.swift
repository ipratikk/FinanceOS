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

    // MARK: - Neon Accent Colors (cyberpunk fintech aesthetic)

    public static let accentCyan = Color(red: 0.0, green: 0.941, blue: 1.0) // #00F0FF — primary action, data highlight
    public static let accentBlue = Color(red: 0.2, green: 0.6, blue: 1.0) // #3399FF — secondary, charts
    public static let accentPurple = Color(red: 0.8, green: 0.2, blue: 1.0) // #CC33FF — tertiary, badges
    public static let accentPink = Color(red: 1.0, green: 0.106, blue: 0.616) // #FF1B9D — alerts, warnings
    public static let accentLime = Color(red: 0.4, green: 1.0, blue: 0.0) // #66FF00 — positive, gains
    public static let accentOrange = Color(red: 1.0, green: 0.4, blue: 0.0) // #FF6600 — negative, losses

    // MARK: - Semantic colors

    public static let accent = accentBlue // Default primary accent
    public static let success = Color(red: 0.0, green: 0.847, blue: 0.4) // #00D966 — positive states
    public static let danger = Color(red: 1.0, green: 0.2, blue: 0.2) // #FF3333 — destructive actions
    public static let info = Color(red: 0.0, green: 0.706, blue: 1.0) // #00B4FF — information

    // MARK: - Legacy semantic colors (mapped for backwards compatibility)

    public static let credit = success // Positive transaction
    public static let debit = accentOrange // Negative transaction
    public static let warning = Color(red: 1.0, green: 0.722, blue: 0.0) // #FFB800 — caution states
    public static let purple = accentPurple

    // MARK: - Text

    public static let textPrimary = Color.white
    public static let textSecondary = Color(red: 0.631, green: 0.631, blue: 0.667) // #A1A1AA
    public static let textTertiary = Color(red: 0.447, green: 0.447, blue: 0.478) // #71717A
    public static let textDisabled = Color(red: 0.322, green: 0.322, blue: 0.361) // #52525B
}

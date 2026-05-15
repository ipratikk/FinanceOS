import SwiftUI

public enum AppColors {
    // MARK: - Backgrounds (elevation layers)

    public static let base = Color(red: 0.051, green: 0.051, blue: 0.059)           // #0D0D0F
    public static let surface = Color(red: 0.086, green: 0.086, blue: 0.098)         // #161618
    public static let surface2 = Color(red: 0.110, green: 0.110, blue: 0.122)        // #1C1C1F
    public static let surface3 = Color(red: 0.141, green: 0.141, blue: 0.157)        // #242428

    // MARK: - Borders

    public static let border = Color(red: 0.165, green: 0.165, blue: 0.180)          // #2A2A2E
    public static let borderAccent = Color(red: 0.227, green: 0.227, blue: 0.251)    // #3A3A40

    // MARK: - Semantic colors

    public static let accent = Color(red: 0.231, green: 0.510, blue: 0.980)          // #3B82F6
    public static let credit = Color(red: 0.133, green: 0.773, blue: 0.368)          // #22C55E
    public static let debit = Color(red: 0.937, green: 0.267, blue: 0.267)           // #EF4444
    public static let warning = Color(red: 0.961, green: 0.620, blue: 0.067)         // #F59E0B
    public static let purple = Color(red: 0.659, green: 0.333, blue: 0.968)          // #A855F7

    // MARK: - Text

    public static let textPrimary = Color.white
    public static let textSecondary = Color(red: 0.631, green: 0.631, blue: 0.667)   // #A1A1AA
    public static let textTertiary = Color(red: 0.447, green: 0.447, blue: 0.478)    // #71717A
    public static let textDisabled = Color(red: 0.322, green: 0.322, blue: 0.361)    // #52525B
}

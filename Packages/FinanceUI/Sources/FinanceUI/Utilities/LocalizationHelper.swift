import SwiftUI

/// Helper for localized strings with String Catalogs.
/// Use: Text("Banks") - Xcode auto-detects and adds to catalog
public struct L10n {
    // Note: String Catalogs (Localizable.xcstrings) automatically
    // extract and track String(localized:) and Text() string literals.
    // Just write natural strings and Xcode manages the catalog.

    // Example usage in SwiftUI:
    // Text("Banks")  // Auto-localized via String Catalog
    // TextField("Search transactions", text: $query)

    // For dynamic strings with parameters, use String(localized:) explicitly:
    // let formatted = String(localized: "Imported \(count) transactions")
}

// MARK: - RTL-Safe Layout Helpers

extension View {
    /// RTL-safe horizontal alignment.
    func rtlLeading() -> some View {
        frame(maxWidth: .infinity, alignment: .leading)
    }

    /// RTL-safe trailing alignment.
    func rtlTrailing() -> some View {
        frame(maxWidth: .infinity, alignment: .trailing)
    }

    /// RTL-safe horizontal flip for icons/images if needed.
    func rtlMirror() -> some View {
        environment(\.layoutDirection, .rightToLeft)
    }
}

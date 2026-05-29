import SwiftUI

/// Namespace for localization guidance. No runtime logic — see inline comments.
///
/// Xcode String Catalogs auto-extract `Text()` and `String(localized:)` literals.
/// Just write natural strings; Xcode manages `Localizable.xcstrings` automatically.
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
    /// Pins content to the leading edge — correct for both LTR and RTL layouts.
    func rtlLeading() -> some View {
        frame(maxWidth: .infinity, alignment: .leading)
    }

    /// Pins content to the trailing edge — correct for both LTR and RTL layouts.
    func rtlTrailing() -> some View {
        frame(maxWidth: .infinity, alignment: .trailing)
    }

    /// Forces right-to-left layout direction on a subtree, e.g. for RTL icon mirroring.
    func rtlMirror() -> some View {
        environment(\.layoutDirection, .rightToLeft)
    }
}

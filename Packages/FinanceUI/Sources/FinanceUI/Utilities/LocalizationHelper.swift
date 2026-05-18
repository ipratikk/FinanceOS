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

// MARK: - Locale-Safe Formatting Helpers

extension NumberFormatter {
    static let currencyINR: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "INR"
        formatter.locale = Locale(identifier: "en_IN")
        return formatter
    }()

    static let currencyUSD: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.locale = Locale(identifier: "en_US")
        return formatter
    }()

    static let decimal: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter
    }()
}

extension DateFormatter {
    static let medium: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    static let mediumTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    static let monthYear: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }()
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

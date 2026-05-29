import FinanceCore
import SwiftUI

/// A single selectable option for use with `FDSPicker`.
///
/// `value` defaults to `id` when not provided — use explicit `value` when the
/// display identifier differs from the selection key.
public struct FDSPickerOption: Identifiable {
    /// Stable identifier for SwiftUI diffing.
    public let id: AnyHashable
    /// The value bound to `FDSPicker.selection` on tap.
    public let value: AnyHashable
    /// Primary display label.
    public let title: String
    /// Optional secondary label shown below title.
    public let subtitle: String?
    /// SF Symbol name shown as fallback when no `imageName` is available.
    public let symbol: String?
    /// Asset catalog image name for the option logo.
    public let imageName: String?
    /// Optional text badge rendered below the subtitle.
    public let badge: String?

    public init(
        id: AnyHashable,
        value: AnyHashable? = nil,
        title: String,
        subtitle: String? = nil,
        symbol: String? = nil,
        imageName: String? = nil,
        badge: String? = nil
    ) {
        self.id = id
        self.value = value ?? id
        self.title = title
        self.subtitle = subtitle
        self.symbol = symbol
        self.imageName = imageName
        self.badge = badge
    }
}

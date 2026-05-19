import FinanceCore
import SwiftUI

public struct FDSPickerOption: Identifiable {
    public let id: AnyHashable
    public let value: AnyHashable
    public let title: String
    public let subtitle: String?
    public let symbol: String?
    public let imageName: String?
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

import SwiftUI

enum CategorySymbol {
    private static let symbols: [String: String] = [
        "income": "arrow.down.circle.fill",
        "transfers": "arrow.left.arrow.right.circle.fill",
        "housing": "house.fill",
        "utilities": "bolt.fill",
        "groceries": "cart.fill",
        "dining": "fork.knife",
        "transportation": "car.fill",
        "travel": "airplane",
        "healthcare": "cross.fill",
        "insurance": "shield.fill",
        "subscriptions": "repeat.circle.fill",
        "shopping": "bag.fill",
        "entertainment": "tv.fill",
        "education": "book.fill",
        "fees": "exclamationmark.circle.fill",
        "taxes": "building.columns.fill",
        "business": "briefcase.fill",
        "atm": "banknote.fill",
        "investments": "chart.line.uptrend.xyaxis"
    ]

    private static let colors: [String: Color] = [
        "income": .green,
        "transfers": .blue,
        "housing": .orange,
        "utilities": .yellow,
        "groceries": .green,
        "dining": .orange,
        "transportation": .blue,
        "travel": .cyan,
        "healthcare": .red,
        "insurance": .indigo,
        "subscriptions": .purple,
        "shopping": .pink,
        "entertainment": .purple,
        "education": .blue,
        "fees": .red,
        "taxes": .gray,
        "business": .brown,
        "atm": .green,
        "investments": .teal
    ]

    static func symbol(for categoryId: String?) -> String {
        guard let categoryId else { return "questionmark.circle.fill" }
        return symbols[categoryId] ?? "questionmark.circle.fill"
    }

    static func color(for categoryId: String?) -> Color {
        guard let categoryId else { return .gray }
        return colors[categoryId] ?? .gray
    }
}

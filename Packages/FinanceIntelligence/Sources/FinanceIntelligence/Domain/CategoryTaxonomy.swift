import Foundation

/// A leaf-level specialization within a `TaxonomyCategory` (e.g. `"dining.delivery"`).
public struct TaxonomySubcategory: Codable, Sendable, Hashable {
    /// Dot-namespaced identifier (e.g. `"dining.delivery"`).
    public let id: String
    /// Human-readable label shown in the UI.
    public let displayName: String

    public init(id: String, displayName: String) {
        self.id = id
        self.displayName = displayName
    }
}

/// A top-level spending category (e.g. `"dining"`) that may contain subcategories.
public struct TaxonomyCategory: Codable, Sendable, Hashable {
    /// Short identifier used in predictions and rules (e.g. `"dining"`).
    public let id: String
    /// Human-readable label shown in the UI.
    public let displayName: String
    /// Zero or more subcategories; empty for leaf-only categories like `"groceries"`.
    public let subcategories: [TaxonomySubcategory]

    public init(id: String, displayName: String, subcategories: [TaxonomySubcategory] = []) {
        self.id = id
        self.displayName = displayName
        self.subcategories = subcategories
    }
}

/// The full two-level category hierarchy used across the intelligence pipeline and UI.
/// Use `CategoryTaxonomy.current` for the active version at runtime.
public struct CategoryTaxonomy: Codable, Sendable {
    /// Semantic version string (e.g. `"1.0.0"`). Must be bumped when categories change.
    public let version: String
    /// All top-level categories in display order.
    public let categories: [TaxonomyCategory]

    public init(version: String, categories: [TaxonomyCategory]) {
        self.version = version
        self.categories = categories
    }

    /// Returns the top-level category matching `id`, or nil if not found.
    public func category(forId id: String) -> TaxonomyCategory? {
        categories.first { $0.id == id }
    }

    /// Searches all subcategories across all top-level categories and returns the first match.
    public func subcategory(forId id: String) -> TaxonomySubcategory? {
        for cat in categories {
            if let sub = cat.subcategories.first(where: { $0.id == id }) { return sub }
        }
        return nil
    }

    /// Flat list of all top-level category IDs in definition order.
    public var allCategoryIds: [String] {
        categories.map(\.id)
    }

    /// The active taxonomy version used at runtime. Update this alias when shipping new taxonomy versions.
    public static let current: CategoryTaxonomy = .v1
}

// MARK: - Default Taxonomy v1.0.0

public extension CategoryTaxonomy {
    /// Built-in taxonomy covering Indian and international bank transaction categories.
    static let v1 = CategoryTaxonomy(
        version: "1.0.0",
        categories: [
            TaxonomyCategory(id: "income", displayName: "Income", subcategories: [
                TaxonomySubcategory(id: "income.salary", displayName: "Salary"),
                TaxonomySubcategory(id: "income.dividend", displayName: "Dividends"),
                TaxonomySubcategory(id: "income.interest", displayName: "Interest"),
                TaxonomySubcategory(id: "income.freelance", displayName: "Freelance"),
                TaxonomySubcategory(id: "income.refund", displayName: "Refund")
            ]),
            TaxonomyCategory(id: "transfers", displayName: "Transfers", subcategories: [
                TaxonomySubcategory(id: "transfers.internal", displayName: "Internal Transfer"),
                TaxonomySubcategory(id: "transfers.external", displayName: "External Transfer")
            ]),
            TaxonomyCategory(id: "housing", displayName: "Housing", subcategories: [
                TaxonomySubcategory(id: "housing.rent", displayName: "Rent"),
                TaxonomySubcategory(id: "housing.mortgage", displayName: "Mortgage"),
                TaxonomySubcategory(id: "housing.maintenance", displayName: "Maintenance")
            ]),
            TaxonomyCategory(id: "utilities", displayName: "Utilities", subcategories: [
                TaxonomySubcategory(id: "utilities.electricity", displayName: "Electricity"),
                TaxonomySubcategory(id: "utilities.water", displayName: "Water"),
                TaxonomySubcategory(id: "utilities.gas", displayName: "Gas"),
                TaxonomySubcategory(id: "utilities.internet", displayName: "Internet"),
                TaxonomySubcategory(id: "utilities.phone", displayName: "Phone")
            ]),
            TaxonomyCategory(id: "groceries", displayName: "Groceries"),
            TaxonomyCategory(id: "dining", displayName: "Restaurants & Dining", subcategories: [
                TaxonomySubcategory(id: "dining.restaurant", displayName: "Restaurant"),
                TaxonomySubcategory(id: "dining.coffee", displayName: "Coffee & Café"),
                TaxonomySubcategory(id: "dining.delivery", displayName: "Food Delivery")
            ]),
            TaxonomyCategory(id: "transportation", displayName: "Transportation", subcategories: [
                TaxonomySubcategory(id: "transportation.rideshare", displayName: "Rideshare"),
                TaxonomySubcategory(id: "transportation.fuel", displayName: "Fuel"),
                TaxonomySubcategory(id: "transportation.parking", displayName: "Parking"),
                TaxonomySubcategory(id: "transportation.transit", displayName: "Public Transit")
            ]),
            TaxonomyCategory(id: "travel", displayName: "Travel", subcategories: [
                TaxonomySubcategory(id: "travel.flight", displayName: "Flights"),
                TaxonomySubcategory(id: "travel.hotel", displayName: "Hotels"),
                TaxonomySubcategory(id: "travel.rental", displayName: "Car Rental")
            ]),
            TaxonomyCategory(id: "healthcare", displayName: "Healthcare", subcategories: [
                TaxonomySubcategory(id: "healthcare.doctor", displayName: "Doctor"),
                TaxonomySubcategory(id: "healthcare.pharmacy", displayName: "Pharmacy"),
                TaxonomySubcategory(id: "healthcare.dental", displayName: "Dental"),
                TaxonomySubcategory(id: "healthcare.vision", displayName: "Vision")
            ]),
            TaxonomyCategory(id: "insurance", displayName: "Insurance", subcategories: [
                TaxonomySubcategory(id: "insurance.health", displayName: "Health Insurance"),
                TaxonomySubcategory(id: "insurance.auto", displayName: "Auto Insurance"),
                TaxonomySubcategory(id: "insurance.life", displayName: "Life Insurance")
            ]),
            TaxonomyCategory(id: "subscriptions", displayName: "Subscriptions", subcategories: [
                TaxonomySubcategory(id: "subscriptions.streaming", displayName: "Streaming"),
                TaxonomySubcategory(id: "subscriptions.music", displayName: "Music"),
                TaxonomySubcategory(id: "subscriptions.software", displayName: "Software"),
                TaxonomySubcategory(id: "subscriptions.news", displayName: "News & Media")
            ]),
            TaxonomyCategory(id: "shopping", displayName: "Shopping", subcategories: [
                TaxonomySubcategory(id: "shopping.online", displayName: "Online Shopping"),
                TaxonomySubcategory(id: "shopping.clothing", displayName: "Clothing"),
                TaxonomySubcategory(id: "shopping.electronics", displayName: "Electronics")
            ]),
            TaxonomyCategory(id: "entertainment", displayName: "Entertainment", subcategories: [
                TaxonomySubcategory(id: "entertainment.movies", displayName: "Movies"),
                TaxonomySubcategory(id: "entertainment.games", displayName: "Games"),
                TaxonomySubcategory(id: "entertainment.sports", displayName: "Sports")
            ]),
            TaxonomyCategory(id: "education", displayName: "Education", subcategories: [
                TaxonomySubcategory(id: "education.tuition", displayName: "Tuition"),
                TaxonomySubcategory(id: "education.books", displayName: "Books"),
                TaxonomySubcategory(id: "education.courses", displayName: "Online Courses")
            ]),
            TaxonomyCategory(id: "fees", displayName: "Fees & Interest", subcategories: [
                TaxonomySubcategory(id: "fees.bank", displayName: "Bank Fees"),
                TaxonomySubcategory(id: "fees.interest", displayName: "Interest Charges"),
                TaxonomySubcategory(id: "fees.late", displayName: "Late Fees")
            ]),
            TaxonomyCategory(id: "taxes", displayName: "Taxes"),
            TaxonomyCategory(id: "business", displayName: "Business"),
            TaxonomyCategory(id: "atm", displayName: "Cash & ATM"),
            TaxonomyCategory(id: "uncategorized", displayName: "Uncategorized")
        ]
    )
}

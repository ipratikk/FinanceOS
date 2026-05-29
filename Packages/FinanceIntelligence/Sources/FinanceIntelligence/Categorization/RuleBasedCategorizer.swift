import Foundation

/// A keyword-based matching rule mapping a set of trigger tokens to a taxonomy category.
/// Rules are evaluated by counting how many keywords are present in the normalized description;
/// the rule with the highest hit count wins.
public struct CategoryRule: Sendable {
    /// Lowercase keyword substrings to search for in the normalized description.
    public let keywords: [String]
    /// Top-level taxonomy category ID assigned when this rule fires (e.g. `"dining"`).
    public let categoryId: String
    /// Optional subcategory ID assigned alongside `categoryId` (e.g. `"dining.delivery"`).
    public let subcategoryId: String?
    /// Prediction confidence emitted when this rule fires, in [0, 1].
    public let confidence: Double

    public init(_ keywords: [String], _ categoryId: String, _ subcategoryId: String? = nil, confidence: Double = 0.8) {
        self.keywords = keywords
        self.categoryId = categoryId
        self.subcategoryId = subcategoryId
        self.confidence = confidence
    }
}

/// Deterministic rule-based categorizer. Scores each transaction by keyword matching.
/// Used as the primary categorizer when no Core ML model is available.
public struct RuleBasedCategorizer: Sendable {
    private let taxonomy: CategoryTaxonomy
    private let rules: [CategoryRule]

    public init(taxonomy: CategoryTaxonomy = .current) {
        self.taxonomy = taxonomy
        rules = Self.buildRules()
    }

    /// Returns the best-matching category for the given feature vector.
    /// Fast-path checks payroll, refund, and transfer indicators before keyword scanning.
    public func categorize(_ features: TransactionFeatures) -> CategoryPrediction {
        if features.hasPayrollIndicator {
            return makePrediction(
                categoryId: "income",
                subcategoryId: "income.salary",
                confidence: 0.9,
                source: .rules
            )
        }
        if features.hasRefundIndicator {
            return makePrediction(
                categoryId: "income",
                subcategoryId: "income.refund",
                confidence: 0.85,
                source: .rules
            )
        }
        if features.hasTransferIndicator {
            return makePrediction(
                categoryId: "transfers",
                subcategoryId: nil,
                confidence: 0.88,
                source: .rules
            )
        }

        let desc = features.normalizedDescription
        var topMatch: (rule: CategoryRule, score: Int)?

        for rule in rules {
            let score = rule.keywords.count(where: { desc.contains($0) })
            guard score > 0 else { continue }
            if topMatch == nil || score > topMatch?.score ?? 0 {
                topMatch = (rule, score)
            }
        }

        if let match = topMatch {
            return makePrediction(
                categoryId: match.rule.categoryId,
                subcategoryId: match.rule.subcategoryId,
                confidence: match.rule.confidence,
                source: .rules
            )
        }

        return .uncategorized(
            modelVersion: ModelMetadata.rulesBased.modelVersion,
            taxonomyVersion: taxonomy.version
        )
    }
}

// MARK: - Prediction Builder

private extension RuleBasedCategorizer {
    func makePrediction(
        categoryId: String,
        subcategoryId: String?,
        confidence: Double,
        source: PredictionSource
    ) -> CategoryPrediction {
        let displayName = taxonomy.category(forId: categoryId)?.displayName ?? categoryId
        return CategoryPrediction(
            categoryId: categoryId,
            subcategoryId: subcategoryId,
            displayName: displayName,
            confidence: confidence,
            alternatives: [],
            source: source,
            modelVersion: ModelMetadata.rulesBased.modelVersion,
            taxonomyVersion: taxonomy.version
        )
    }
}

// MARK: - Default Rules

private extension RuleBasedCategorizer {
    /// Assembles all rule groups into the ordered rule list evaluated at categorization time.
    static func buildRules() -> [CategoryRule] {
        incomeRules + transferRules + housingUtilityRules +
            groceryDiningRules + transportTravelRules +
            healthInsuranceRules + subscriptionRules +
            shoppingEntertainmentRules + miscRules
    }

    static var incomeRules: [CategoryRule] {
        [
            CategoryRule(["salary", "payroll", "paycheck", "wages"], "income", "income.salary", confidence: 0.9),
            CategoryRule(["dividend", "interest earned", "interest credit"], "income", "income.dividend"),
            CategoryRule(["freelance", "consulting fee", "invoice"], "income", "income.freelance"),
            CategoryRule(["refund", "cashback", "reversal"], "income", "income.refund", confidence: 0.85),
            CategoryRule(["inw ", "swift inward", "forex credit", "usd@", "usd2"], "income")
        ]
    }

    static var transferRules: [CategoryRule] {
        [
            CategoryRule(
                ["neft", "imps", "rtgs", "upi transfer", "wire transfer", "ach transfer"],
                "transfers", nil, confidence: 0.88
            )
        ]
    }

    static var housingUtilityRules: [CategoryRule] {
        [
            CategoryRule(["rent", "lease payment", "housing"], "housing", "housing.rent"),
            CategoryRule(["mortgage", "home loan emi", "housing loan"], "housing", "housing.mortgage"),
            CategoryRule(["electricity", "power bill", "electric bill"], "utilities", "utilities.electricity"),
            CategoryRule(
                ["internet", "broadband", "wifi", "airtel", "jio", "comcast", "at&t"],
                "utilities", "utilities.internet"
            ),
            CategoryRule(["phone bill", "mobile bill", "wireless"], "utilities", "utilities.phone")
        ]
    }

    static var groceryDiningRules: [CategoryRule] {
        [
            CategoryRule(
                ["grocery", "groceries", "supermarket", "d-mart", "big bazaar", "reliance fresh"],
                "groceries"
            ),
            CategoryRule(
                ["restaurant", "cafe", "diner", "eatery", "food court", "sweetgreen", "chipotle"],
                "dining", "dining.restaurant"
            ),
            CategoryRule(["starbucks", "coffee", "blue bottle", "third wave"], "dining", "dining.coffee"),
            CategoryRule(
                ["doordash", "swiggy", "zomato", "ubereats", "grubhub", "food delivery"],
                "dining", "dining.delivery"
            )
        ]
    }

    static var transportTravelRules: [CategoryRule] {
        [
            CategoryRule(["uber", "lyft", "ola", "rapido"], "transportation", "transportation.rideshare"),
            CategoryRule(
                ["petrol", "fuel", "gasoline", "shell", "bp ", "exxon", "indian oil"],
                "transportation", "transportation.fuel"
            ),
            CategoryRule(["parking", "park fee"], "transportation", "transportation.parking"),
            CategoryRule(
                ["metro", "subway", "bus pass", "transit", "train ticket"],
                "transportation", "transportation.transit"
            ),
            CategoryRule(
                ["flight", "airline", "airways", "air india", "indigo", "makemytrip"],
                "travel", "travel.flight"
            ),
            CategoryRule(["hotel", "airbnb", "booking.com", "oyo rooms"], "travel", "travel.hotel")
        ]
    }

    static var healthInsuranceRules: [CategoryRule] {
        [
            CategoryRule(
                ["pharmacy", "chemist", "medicine", "apollo pharmacy", "walgreens", "cvs"],
                "healthcare", "healthcare.pharmacy"
            ),
            CategoryRule(
                ["doctor", "clinic", "hospital", "consultation", "diagnostic"],
                "healthcare", "healthcare.doctor"
            ),
            CategoryRule(
                ["max life ins", "lic premium", "hdfc life", "icici pru", "star health", "bajaj allianz", "tp-max"],
                "insurance"
            ),
            CategoryRule(["ecs debit", "nach debit"], "insurance")
        ]
    }

    static var subscriptionRules: [CategoryRule] {
        [
            CategoryRule(
                ["spotify", "apple music", "youtube music", "gaana"], "subscriptions", "subscriptions.music"
            ),
            CategoryRule(
                ["netflix", "hulu", "disney", "prime video", "hotstar"],
                "subscriptions", "subscriptions.streaming"
            ),
            CategoryRule(
                ["microsoft", "adobe", "notion", "slack", "github", "dropbox"],
                "subscriptions", "subscriptions.software"
            )
        ]
    }

    static var shoppingEntertainmentRules: [CategoryRule] {
        [
            CategoryRule(["amazon", "flipkart", "myntra", "nykaa", "meesho"], "shopping", "shopping.online"),
            CategoryRule(["giva", "tanishq", "malabar", "kalyan jewellers"], "shopping"),
            CategoryRule(["movie", "cinema", "pvr", "inox", "amc"], "entertainment", "entertainment.movies")
        ]
    }

    static var miscRules: [CategoryRule] {
        [
            CategoryRule(["tuition", "school fee", "college fee", "udemy", "coursera"], "education"),
            CategoryRule(
                ["bank fee", "annual fee", "service charge", "maintenance charge"], "fees", "fees.bank"
            ),
            CategoryRule(["interest charged", "finance charge", "late fee"], "fees", "fees.interest"),
            CategoryRule(["atm withdrawal", "cash withdrawal", "atm cash"], "atm"),
            CategoryRule(["income tax", "gst payment", "tds"], "taxes"),
            CategoryRule(["ach d-", "sip debit", "mutual fund", "zerodha", "groww", "kuvera"], "business")
        ]
    }
}

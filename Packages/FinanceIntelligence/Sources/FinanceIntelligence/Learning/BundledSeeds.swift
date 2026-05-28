import Foundation

// Seed examples bundled with the app for cold-start accuracy.
// These are generic labeled descriptions derived from the alias table and common patterns.
// User corrections automatically override and supplement these over time.
enum BundledSeeds {
    static func load() -> [LocalTransactionLearner.LabeledExample] {
        seeds.map { desc, category in
            LocalTransactionLearner.LabeledExample(
                tokens: tokenize(desc),
                categoryId: category,
                addedAt: .distantPast,
                isUserProvided: false,
                appVersion: "seeds-1.0"
            )
        }
    }

    private static func tokenize(_ text: String) -> [String] {
        text.lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { $0.count >= 2 }
    }

    // (normalized description, categoryId)
    private static let seeds: [(String, String)] = [
        // Income
        ("salary credit monthly", "income"),
        ("payroll deposit direct", "income"),
        ("neft cr paypal india salary", "income"),
        ("inward wire transfer usd salary", "income"),
        ("bonus credit annual", "income"),
        ("freelance payment invoice", "income"),
        ("refund credit amazon", "income"),

        // Transfers
        ("neft dr transfer rent", "transfers"),
        ("upi transfer personal", "transfers"),
        ("imps transfer", "transfers"),
        ("rtgs payment", "transfers"),
        ("cred club payment credit card", "transfers"),
        ("american express payment upi", "transfers"),
        ("hdfc credit card bill payment", "transfers"),

        // Groceries
        ("zepto grocery order", "groceries"),
        ("blinkit grocery delivery", "groceries"),
        ("big basket order groceries", "groceries"),
        ("dmart supermarket purchase", "groceries"),
        ("reliance fresh grocery", "groceries"),
        ("whole foods market grocery", "groceries"),
        ("trader joes grocery", "groceries"),
        ("kroger supermarket", "groceries"),

        // Dining
        ("starbucks coffee", "dining"),
        ("cafe coffee third wave", "dining"),
        ("restaurant dining out food", "dining"),
        ("sweetgreen salad", "dining"),
        ("chipotle burrito", "dining"),
        ("mcdonalds burger fast food", "dining"),
        ("pizza hut pizza delivery", "dining"),
        ("dominos pizza order", "dining"),

        // Delivery
        ("swiggy food delivery order", "dining"),
        ("zomato food order delivery", "dining"),
        ("doordash delivery meal", "dining"),
        ("ubereats food delivery", "dining"),

        // Transportation
        ("uber ride trip", "transportation"),
        ("ola cab booking", "transportation"),
        ("lyft ride", "transportation"),
        ("rapido bike taxi", "transportation"),
        ("metro card recharge transit", "transportation"),
        ("fuel petrol pump", "transportation"),
        ("parking fee", "transportation"),

        // Subscriptions
        ("spotify premium music", "subscriptions"),
        ("netflix streaming monthly", "subscriptions"),
        ("apple media services subscription", "subscriptions"),
        ("google one storage subscription", "subscriptions"),
        ("hotstar premium subscription", "subscriptions"),
        ("amazon prime membership", "subscriptions"),
        ("microsoft office subscription", "subscriptions"),
        ("youtube premium subscription", "subscriptions"),

        // Utilities
        ("airtel postpaid bill mobile", "utilities"),
        ("jio recharge mobile data", "utilities"),
        ("electricity bill payment bescom", "utilities"),
        ("act fibernet broadband internet", "utilities"),
        ("water bill payment", "utilities"),

        // Healthcare
        ("apollo pharmacy medicine", "healthcare"),
        ("pharmeasy medicine order", "healthcare"),
        ("doctor consultation clinic", "healthcare"),
        ("lab test diagnostic", "healthcare"),
        ("pharmacy chemist medicine purchase", "healthcare"),

        // Insurance
        ("max life insurance premium", "insurance"),
        ("lic policy premium payment", "insurance"),
        ("health insurance premium star", "insurance"),
        ("hdfc life insurance emi", "insurance"),

        // Shopping
        ("amazon marketplace purchase", "shopping"),
        ("flipkart order online", "shopping"),
        ("myntra clothing fashion", "shopping"),
        ("giva jewellery purchase", "shopping"),

        // Housing
        ("house rent payment monthly", "housing"),
        ("rent transfer landlord", "housing"),

        // Fees
        ("bank annual fee credit card", "fees"),
        ("late payment charge fee", "fees"),
        ("atm withdrawal charges bank", "fees"),

        // ATM
        ("atm cash withdrawal", "atm"),
        ("cash withdrawal atm machine", "atm"),

        // Business / Investments
        ("sip debit mutual fund investment", "business"),
        ("ach debit clearing corporation sip", "business"),
        ("zerodha equity purchase", "business"),
        ("groww mutual fund sip", "business"),

        // Taxes
        ("income tax payment tds", "taxes"),
        ("gst payment government tax", "taxes"),
    ]
}

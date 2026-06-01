import Foundation

/// Example for dataset seeding.
public struct PersonMerchantExample {
    public let narration: String
    public let label: String
    public let bank: String
}

/// Seed dataset for person/merchant classification training (ML-001).
///
/// This file contains manually verified examples extracted from parser fixtures
/// and annotated according to ANNOTATION_GUIDELINES.
public enum PersonMerchantDataset {
    /// Initial seed examples from parser test fixtures.
    public static let seedExamples: [PersonMerchantExample] = [
        // HDFC Bank narrations
        PersonMerchantExample(narration: "UPI/123456/Grocery Store/PhonePe", label: "merchant", bank: "HDFC"),
        PersonMerchantExample(narration: "NEFT/987654/Salary Credit", label: "person", bank: "HDFC"),
        PersonMerchantExample(narration: "ATM/WDL/ABC Road", label: "unknown", bank: "HDFC"),
        PersonMerchantExample(narration: "UPI/111222/Refund from Amazon", label: "merchant", bank: "HDFC"),

        // ICICI Bank narrations
        PersonMerchantExample(narration: "UPI/PhonePe/Grocery", label: "merchant", bank: "ICICI"),
        PersonMerchantExample(narration: "NEFT CR/Salary", label: "person", bank: "ICICI"),
        PersonMerchantExample(narration: "ATM Withdrawal", label: "unknown", bank: "ICICI"),
        PersonMerchantExample(narration: "Refund Credit", label: "unknown", bank: "ICICI"),

        // Additional person P2P examples (phone number VPAs)
        PersonMerchantExample(narration: "UPI-JOHN DOE-9876543210@upi-HDFC0-REF1", label: "person", bank: "HDFC"),
        PersonMerchantExample(narration: "UPI-RAJESH SHARMA-9123456789@ybl-ICIC0-REF2", label: "person", bank: "ICICI"),
        PersonMerchantExample(narration: "NEFT CR-HDFC0-PRIYA PATEL-REF3", label: "person", bank: "HDFC"),

        // Merchant examples with business indicators
        PersonMerchantExample(narration: "UPI-SWIGGY-swiggy@swiggypay-HDFC0-REF4", label: "merchant", bank: "HDFC"),
        PersonMerchantExample(narration: "UPI-AMAZON-amazonpay@razorpay-ICIC0-REF5", label: "merchant", bank: "ICICI"),
        PersonMerchantExample(narration: "NEFT DR-ICIC0-NETFLIX INDIA PVT LTD-REF6", label: "merchant", bank: "ICICI"),
        PersonMerchantExample(narration: "UPI-ZOMATO INDIA-zomato@sbi-REF7", label: "merchant", bank: "HDFC"),
        PersonMerchantExample(
            narration: "NEFT CR-ICIC0-UBER INDIA PRIVATE LIMITED-REF8",
            label: "merchant",
            bank: "ICICI"
        ),

        // Ambiguous/unknown examples
        PersonMerchantExample(narration: "NEFT-UNKNOWN-ABC123", label: "unknown", bank: "HDFC"),
        PersonMerchantExample(narration: "TRANSFER REFERENCE XYZ", label: "unknown", bank: "ICICI"),
        PersonMerchantExample(narration: "INT PAID", label: "unknown", bank: "HDFC")
    ]

    /// Example for testing with guaranteed person label.
    public static let personExample = PersonMerchantExample(
        narration: "UPI-RAJESH-9876543210@upi-HDFC0-REF",
        label: "person",
        bank: "HDFC"
    )

    /// Example for testing with guaranteed merchant label.
    public static let merchantExample = PersonMerchantExample(
        narration: "UPI-SWIGGY-swiggy@swiggypay-HDFC0-REF",
        label: "merchant",
        bank: "HDFC"
    )

    /// Example for testing with ambiguous label.
    public static let unknownExample = PersonMerchantExample(
        narration: "NEFT-UNKNOWN",
        label: "unknown",
        bank: "HDFC"
    )
}

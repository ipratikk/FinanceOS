import Foundation

/// Seed dataset for person/merchant classification training (ML-001).
///
/// This file contains manually verified examples extracted from parser fixtures
/// and annotated according to ANNOTATION_GUIDELINES.
public enum PersonMerchantDataset {
    /// Initial seed examples from parser test fixtures.
    public static let seedExamples: [(narration: String, label: String, bank: String)] = [
        // HDFC Bank narrations
        ("UPI/123456/Grocery Store/PhonePe", "merchant", "HDFC"),
        ("NEFT/987654/Salary Credit", "person", "HDFC"),
        ("ATM/WDL/ABC Road", "unknown", "HDFC"),
        ("UPI/111222/Refund from Amazon", "merchant", "HDFC"),

        // ICICI Bank narrations
        ("UPI/PhonePe/Grocery", "merchant", "ICICI"),
        ("NEFT CR/Salary", "person", "ICICI"),
        ("ATM Withdrawal", "unknown", "ICICI"),
        ("Refund Credit", "unknown", "ICICI"),

        // Additional person P2P examples (phone number VPAs)
        ("UPI-JOHN DOE-9876543210@upi-HDFC0-REF1", "person", "HDFC"),
        ("UPI-RAJESH SHARMA-9123456789@ybl-ICIC0-REF2", "person", "ICICI"),
        ("NEFT CR-HDFC0-PRIYA PATEL-REF3", "person", "HDFC"),

        // Merchant examples with business indicators
        ("UPI-SWIGGY-swiggy@swiggypay-HDFC0-REF4", "merchant", "HDFC"),
        ("UPI-AMAZON-amazonpay@razorpay-ICIC0-REF5", "merchant", "ICICI"),
        ("NEFT DR-ICIC0-NETFLIX INDIA PVT LTD-REF6", "merchant", "ICICI"),
        ("UPI-ZOMATO INDIA-zomato@sbi-REF7", "merchant", "HDFC"),
        ("NEFT CR-ICIC0-UBER INDIA PRIVATE LIMITED-REF8", "merchant", "ICICI"),

        // Ambiguous/unknown examples
        ("NEFT-UNKNOWN-ABC123", "unknown", "HDFC"),
        ("TRANSFER REFERENCE XYZ", "unknown", "ICICI"),
        ("INT PAID", "unknown", "HDFC"),
    ]

    /// Example for testing with guaranteed person label.
    public static let personExample = ("UPI-RAJESH-9876543210@upi-HDFC0-REF", "person", "HDFC")

    /// Example for testing with guaranteed merchant label.
    public static let merchantExample = ("UPI-SWIGGY-swiggy@swiggypay-HDFC0-REF", "merchant", "HDFC")

    /// Example for testing with ambiguous label.
    public static let unknownExample = ("NEFT-UNKNOWN", "unknown", "HDFC")
}

#!/usr/bin/env swift
//
// Export ML-001 dataset for annotation/training
// Usage: swift Scripts/export_ml_dataset.swift [json|csv]
//

import Foundation

// Seed data from PersonMerchantDataset
let seedExamples: [(String, String, String)] = [
    ("UPI-JOHN DOE-9876543210@upi-HDFC0-REF1", "person", "HDFC"),
    ("UPI-RAJESH SHARMA-9123456789@ybl-ICIC0-REF2", "person", "ICICI"),
    ("NEFT CR-HDFC0-PRIYA PATEL-REF3", "person", "HDFC"),
    ("UPI-SWIGGY-swiggy@swiggypay-HDFC0-REF6", "merchant", "HDFC"),
    ("UPI-AMAZON-amazonpay@razorpay-ICIC0-REF7", "merchant", "ICICI"),
    ("NEFT DR-ICIC0-NETFLIX INDIA PVT LTD-REF8", "merchant", "ICICI"),
    ("UPI-ZOMATO-zomato@sbi-REF9", "merchant", "SBI"),
    ("NEFT CR-HDFC0-UBER INDIA-REF10", "merchant", "HDFC"),
    ("NEFT-UNKNOWN-ABC123", "unknown", "HDFC"),
]

// Synthetic examples for underrepresented patterns
let syntheticExamples: [(String, String)] = [
    ("UPI-ASHOK KUMAR-9876543210@upi-HDFC0-REF", "person"),
    ("UPI-DEEPA SINGH-9123456789@ybl-ICIC0-REF", "person"),
    ("UPI-MYNTRA-myntra@swiggypay-REF", "merchant"),
    ("UPI-AJIO-ajio@swiggypay-REF", "merchant"),
    ("NEFT CR-HDFC0-NYKAA INDIA PVT LTD-REF", "merchant"),
    ("UPI-ABC123-REF456", "unknown"),
    ("TRANSFER REFERENCE XYZ", "unknown"),
]

// Format selection
let format = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "csv"

// Export CSV format
if format == "csv" {
    var rows = ["narration,label,bank,source"]

    // Add seed examples
    for (narration, label, bank) in seedExamples {
        let escaped = narration.contains(",") ? "\"\(narration)\"" : narration
        rows.append("\(escaped),\(label),\(bank),parser_fixture")
    }

    // Add synthetic examples
    for (narration, label) in syntheticExamples {
        let escaped = narration.contains(",") ? "\"\(narration)\"" : narration
        rows.append("\(escaped),\(label),synthetic,synthetic")
    }

    print(rows.joined(separator: "\n"))
}

// Export JSON format
else if format == "json" {
    var examples: [[String: String]] = []

    // Add seed examples
    for (narration, label, bank) in seedExamples {
        examples.append([
            "narration": narration,
            "label": label,
            "bank": bank,
            "source": "parser_fixture"
        ])
    }

    // Add synthetic examples
    for (narration, label) in syntheticExamples {
        examples.append([
            "narration": narration,
            "label": label,
            "bank": "synthetic",
            "source": "synthetic"
        ])
    }

    let dict: [String: Any] = [
        "version": "1.0",
        "created_at": ISO8601DateFormatter().string(from: Date()),
        "total_examples": examples.count,
        "examples": examples
    ]

    if let json = try? JSONSerialization.data(withJSONObject: dict, options: .prettyPrinted),
       let jsonString = String(data: json, encoding: .utf8) {
        print(jsonString)
    }
}

else {
    print("Usage: swift Scripts/export_ml_dataset.swift [json|csv]")
    print("  csv  - Export as CSV for spreadsheet annotation")
    print("  json - Export as JSON for programmatic import")
}

#!/usr/bin/env swift
//
// Dataset collection utility for ML-001
// Extracts narrations from parser test fixtures for initial annotation
//

import Foundation

// Usage: swift Scripts/collect_dataset.swift > dataset_seed.json

let fixtureBase = "Packages/FinanceParsers/Tests/Fixtures"

struct Example {
    let narration: String
    let bank: String
    let source: String
    let suggestedLabel: String
}

var examples: [Example] = []

// Extract from HDFC Bank
if let hdfc = try? String(contentsOfFile: "\(fixtureBase)/hdfc_bank.txt", encoding: .utf8) {
    let lines = hdfc.split(separator: "\n")
    for line in lines.dropFirst() { // skip header
        let fields = line.split(separator: ",", omittingEmptySubsequences: false)
        if fields.count > 1 {
            let narration = String(fields[1]).trimmingCharacters(in: .whitespacesAndNewlines)
            if !narration.isEmpty {
                examples.append(Example(
                    narration: narration,
                    bank: "HDFC",
                    source: "parser_fixture",
                    suggestedLabel: suggestLabel(narration)
                ))
            }
        }
    }
}

// Extract from HDFC Card
if let hdfc = try? String(contentsOfFile: "\(fixtureBase)/hdfc_card.csv", encoding: .utf8) {
    let lines = hdfc.split(separator: "\n")
    for line in lines.dropFirst() {
        let fields = line.split(separator: ",", omittingEmptySubsequences: false)
        if fields.count > 2 {
            let narration = String(fields[2]).trimmingCharacters(in: .whitespacesAndNewlines)
            if !narration.isEmpty {
                examples.append(Example(
                    narration: narration,
                    bank: "HDFC",
                    source: "parser_fixture",
                    suggestedLabel: suggestLabel(narration)
                ))
            }
        }
    }
}

// Extract from ICICI Bank
if let icici = try? String(contentsOfFile: "\(fixtureBase)/icici_bank.csv", encoding: .utf8) {
    let lines = icici.split(separator: "\n")
    for line in lines.dropFirst() {
        let fields = line.split(separator: ",", omittingEmptySubsequences: false)
        if fields.count > 2 {
            let narration = String(fields[2]).trimmingCharacters(in: .whitespacesAndNewlines)
            if !narration.isEmpty {
                examples.append(Example(
                    narration: narration,
                    bank: "ICICI",
                    source: "parser_fixture",
                    suggestedLabel: suggestLabel(narration)
                ))
            }
        }
    }
}

// Extract from ICICI Card
if let icici = try? String(contentsOfFile: "\(fixtureBase)/icici_card.csv", encoding: .utf8) {
    let lines = icici.split(separator: "\n")
    for line in lines.dropFirst() {
        let fields = line.split(separator: ",", omittingEmptySubsequences: false)
        if fields.count > 2 {
            let narration = String(fields[2]).trimmingCharacters(in: .whitespacesAndNewlines)
            if !narration.isEmpty {
                examples.append(Example(
                    narration: narration,
                    bank: "ICICI",
                    source: "parser_fixture",
                    suggestedLabel: suggestLabel(narration)
                ))
            }
        }
    }
}

// Extract from Amex
if let amex = try? String(contentsOfFile: "\(fixtureBase)/amex_card.csv", encoding: .utf8) {
    let lines = amex.split(separator: "\n")
    for line in lines.dropFirst() {
        let fields = line.split(separator: ",", omittingEmptySubsequences: false)
        if fields.count > 3 {
            let narration = String(fields[3]).trimmingCharacters(in: .whitespacesAndNewlines)
            if !narration.isEmpty {
                examples.append(Example(
                    narration: narration,
                    bank: "AMEX",
                    source: "parser_fixture",
                    suggestedLabel: suggestLabel(narration)
                ))
            }
        }
    }
}

/// Output as CSV for manual annotation
var csv = ["narration,bank,source,suggested_label"]
for ex in examples {
    let escaped = ex.narration.contains(",") ? "\"\(ex.narration)\"" : ex.narration
    csv.append("\(escaped),\(ex.bank),\(ex.source),\(ex.suggestedLabel)")
}

print(csv.joined(separator: "\n"))

func suggestLabel(_ narration: String) -> String {
    let lower = narration.lowercased()
    let merchants = ["amazon", "swiggy", "zomato", "flipkart", "uber", "ola", "airtel", "jio", "bank", "insurance"]
    if merchants.contains(where: { lower.contains($0) }) {
        return "merchant"
    }
    if narration.contains("@") {
        if let prefix = narration.components(separatedBy: "@").first?.components(separatedBy: "-").last {
            let digits = prefix.filter(\.isNumber)
            if digits.count == 10 || digits.count == 12 {
                return "person"
            }
        }
    }
    return "unknown"
}

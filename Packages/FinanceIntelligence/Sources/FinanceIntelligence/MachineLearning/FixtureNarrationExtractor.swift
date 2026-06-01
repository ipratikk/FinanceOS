import Foundation

/// Extracts narrations from parser test fixtures for initial dataset seeding.
///
/// Use cases:
/// 1. Bootstrap labeled dataset from real bank statements
/// 2. Verify parser output for manual annotation
/// 3. Create fixture-based benchmark data
public struct FixtureNarrationExtractor {
    /// Parse CSV fixture and extract narrations with basic labels.
    /// Format: assumes column 2 (index 1) contains narration.
    public static func extractFromCSV(
        content: String,
        bank: String,
        narrationColumnIndex: Int = 1
    ) -> [FixtureNarration] {
        var examples: [FixtureNarration] = []
        let lines = content.split(separator: "\n", omittingEmptySubsequences: false)

        for (index, line) in lines.enumerated() {
            if index == 0 { continue } // skip header
            let fields = line.split(separator: ",", omittingEmptySubsequences: false)
            if fields.count <= narrationColumnIndex { continue }

            let narration = String(fields[narrationColumnIndex]).trimmingCharacters(in: .whitespacesAndNewlines)
            if narration.isEmpty { continue }

            let example = FixtureNarration(
                narration: narration,
                bank: bank,
                suggestedLabel: inferLabel(from: narration)
            )
            examples.append(example)
        }

        return examples
    }

    /// Parse TXT fixture (space/tab delimited).
    public static func extractFromTXT(
        content: String,
        bank: String,
        narrationColumnIndex: Int = 1
    ) -> [FixtureNarration] {
        var examples: [FixtureNarration] = []
        let lines = content.split(separator: "\n", omittingEmptySubsequences: false)

        for (index, line) in lines.enumerated() {
            if index == 0 { continue } // skip header
            let fields = line.split(separator: ",", omittingEmptySubsequences: false)
            if fields.count <= narrationColumnIndex { continue }

            let narration = String(fields[narrationColumnIndex]).trimmingCharacters(in: .whitespacesAndNewlines)
            if narration.isEmpty { continue }

            let example = FixtureNarration(
                narration: narration,
                bank: bank,
                suggestedLabel: inferLabel(from: narration)
            )
            examples.append(example)
        }

        return examples
    }

    /// Infer likely label from narration heuristics.
    private static func inferLabel(from narration: String) -> String {
        let lower = narration.lowercased()

        // Merchant indicators (check first)
        let merchantKeywords = [
            "amazon", "swiggy", "zomato", "flipkart", "netflix", "spotify",
            "ola", "uber", "airtel", "jio", "razorpay", "cashfree",
            "marketplace", "pvt", "ltd", "private limited", "llp",
            "hdfc", "icici", "bank", "insurance"
        ]
        if merchantKeywords.contains(where: { lower.contains($0) }) {
            return "merchant"
        }

        // Person indicators (VPA with phone number)
        if narration.contains("@") {
            // Extract part before @ (VPA identifier part)
            if let atIndex = narration.firstIndex(of: "@"),
               let beforeAt = narration[..<atIndex].split(separator: "-").last {
                let vpaId = String(beforeAt).trimmingCharacters(in: .whitespaces)
                // Check if it's a 10 or 12 digit number (phone)
                if vpaId.allSatisfy(\.isNumber) && (vpaId.count == 10 || vpaId.count == 12) {
                    return "person"
                }
            }
        }

        // Default to unknown for ambiguous narrations
        return "unknown"
    }
}

/// Extracted narration from fixture with suggested label.
public struct FixtureNarration: Identifiable {
    public let id: UUID
    public let narration: String
    public let bank: String
    public let suggestedLabel: String

    public init(narration: String, bank: String, suggestedLabel: String) {
        self.id = UUID()
        self.narration = narration
        self.bank = bank
        self.suggestedLabel = suggestedLabel
    }
}

extension FixtureNarration: CustomStringConvertible {
    public var description: String {
        "\(narration) [\(suggestedLabel)] from \(bank)"
    }
}

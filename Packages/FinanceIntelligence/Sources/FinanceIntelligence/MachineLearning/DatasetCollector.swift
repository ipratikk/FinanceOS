import Foundation

/// Collects labeled narration examples from multiple sources for ML-001 training dataset.
public actor DatasetCollector {
    private var examples: [LabeledNarration] = []
    private let annotationGuidelines: String

    public init(annotationGuidelines: String = "") {
        self.annotationGuidelines = annotationGuidelines
    }

    /// Add example from user correction feedback.
    public func addFromUserCorrection(
        narration: String,
        merchantName: String?,
        label: LabeledNarration.NarrationLabel,
        bank: String,
        direction: LabeledNarration.TransactionDirection,
        amountMinorUnits: Int64 = 0
    ) {
        let example = LabeledNarration(
            narration: narration,
            vpa: extractVPA(from: narration),
            amountMinorUnits: amountMinorUnits,
            direction: direction,
            label: label,
            bank: bank,
            source: .userCorrection
        )
        examples.append(example)
    }

    /// Add example from parser test fixture.
    public func addFromFixture(
        narration: String,
        label: LabeledNarration.NarrationLabel,
        bank: String,
        direction: LabeledNarration.TransactionDirection,
        amountMinorUnits: Int64 = 0
    ) {
        let example = LabeledNarration(
            narration: narration,
            vpa: extractVPA(from: narration),
            amountMinorUnits: amountMinorUnits,
            direction: direction,
            label: label,
            bank: bank,
            source: .parserFixture
        )
        examples.append(example)
    }

    /// Add synthetic example for underrepresented patterns.
    public func addSynthetic(
        narration: String,
        label: LabeledNarration.NarrationLabel,
        bank: String,
        direction: LabeledNarration.TransactionDirection,
        amountMinorUnits: Int64 = 0
    ) {
        let example = LabeledNarration(
            narration: narration,
            vpa: extractVPA(from: narration),
            amountMinorUnits: amountMinorUnits,
            direction: direction,
            label: label,
            bank: bank,
            source: .synthetic
        )
        examples.append(example)
    }

    /// Get current dataset snapshot.
    public func buildDataset() -> LabeledNarrationCollection {
        LabeledNarrationCollection(examples: examples, annotationGuidelines: annotationGuidelines)
    }

    /// Export as JSON for external tools.
    public func exportJSON() throws -> Data {
        let collection = buildDataset()
        return try JSONEncoder().encode(collection)
    }

    /// Export as CSV for spreadsheet annotation.
    public func exportCSV() -> String {
        var rows = ["narration,label,bank,source,direction,vpa"]
        for example in examples {
            rows.append([
                csvEscape(example.narration),
                example.label.rawValue,
                example.bank,
                example.source.rawValue,
                example.direction.rawValue,
                csvEscape(example.vpa ?? "")
            ].joined(separator: ","))
        }
        return rows.joined(separator: "\n")
    }

    /// Import annotated CSV (narration,label,bank,source).
    public func importCSV(_ content: String) throws {
        let lines = content.split(separator: "\n", omittingEmptySubsequences: false)
        for (index, line) in lines.enumerated() {
            if index == 0 { continue } // skip header
            let fields = line.split(separator: ",", omittingEmptySubsequences: false)
            if fields.count < 4 { continue }

            let narration = String(fields[0]).trimmingCharacters(in: .whitespacesAndNewlines)
            let labelStr = String(fields[1]).trimmingCharacters(in: .whitespacesAndNewlines)
            let bank = String(fields[2]).trimmingCharacters(in: .whitespacesAndNewlines)
            let sourceStr = String(fields[3]).trimmingCharacters(in: .whitespacesAndNewlines)

            guard let label = LabeledNarration.NarrationLabel(rawValue: labelStr),
                  let source = LabeledNarration.DataSource(rawValue: sourceStr) else {
                continue
            }

            let example = LabeledNarration(
                narration: narration,
                vpa: extractVPA(from: narration),
                amountMinorUnits: 0,
                direction: .debit,
                label: label,
                bank: bank,
                source: source
            )
            examples.append(example)
        }
    }

    /// Statistics snapshot.
    public func statistics() async -> DatasetStatistics {
        let collection = buildDataset()
        return DatasetStatistics(metadata: collection.metadata)
    }

    // MARK: - Private

    private func extractVPA(from narration: String) -> String? {
        guard let range = narration.range(of: #"[a-z0-9]+@[a-z0-9]+"#, options: .regularExpression) else {
            return nil
        }
        return String(narration[range]).lowercased()
    }

    private func csvEscape(_ value: String) -> String {
        if value.contains(",") || value.contains("\"") || value.contains("\n") {
            return "\"\(value.replacingOccurrences(of: "\"", with: "\"\""))\""
        }
        return value
    }
}

/// Dataset collection statistics.
public struct DatasetStatistics: Sendable {
    public let totalCount: Int
    public let personCount: Int
    public let merchantCount: Int
    public let unknownCount: Int
    public let bankCoverage: [String: Int]
    public let sourceCoverage: [String: Int]

    init(metadata: LabeledNarrationCollection.CollectionMetadata) {
        self.totalCount = metadata.totalCount
        self.personCount = metadata.personCount
        self.merchantCount = metadata.merchantCount
        self.unknownCount = metadata.unknownCount
        self.bankCoverage = metadata.bankCoverage
        self.sourceCoverage = metadata.sourceCoverage
    }

    public var summary: String {
        """
        Dataset Statistics
        ==================
        Total examples:     \(totalCount)
        Person:             \(personCount) (\(String(format: "%.1f", Double(personCount) / Double(totalCount) * 100))%)
        Merchant:           \(merchantCount) (\(String(format: "%.1f", Double(merchantCount) / Double(totalCount) * 100))%)
        Unknown:            \(unknownCount) (\(String(format: "%.1f", Double(unknownCount) / Double(totalCount) * 100))%)

        Bank Coverage:
        \(bankCoverage.map { "  \($0.key): \($0.value)" }.joined(separator: "\n"))

        Source Coverage:
        \(sourceCoverage.map { "  \($0.key): \($0.value)" }.joined(separator: "\n"))
        """
    }
}

import Foundation

/// Validates labeled dataset quality and coverage.
///
/// Checks:
/// - Balance (person/merchant/unknown ratios)
/// - Coverage (banks, sources)
/// - Duplication
/// - PII leaks
public struct DatasetValidator {
    public struct ValidationReport: Codable, Sendable {
        public let isValid: Bool
        public let issues: [ValidationIssue]
        public let warnings: [ValidationWarning]
        public let metrics: ValidationMetrics

        public var summary: String {
            """
            Dataset Validation Report
            =========================
            Status: \(isValid ? "✓ VALID" : "✗ INVALID")

            Issues: \(issues.count)
            Warnings: \(warnings.count)

            \(metrics.summary)
            """
        }
    }

    public struct ValidationIssue: Codable, Sendable {
        public let code: String
        public let message: String
    }

    public struct ValidationWarning: Codable, Sendable {
        public let code: String
        public let message: String
    }

    public struct ValidationMetrics: Codable, Sendable {
        public let totalExamples: Int
        public let uniqueExamples: Int
        public let duplicateCount: Int
        public let balance: [String: Double]
        public let bankCoverage: [String: Int]
        public let sourceCoverage: [String: Int]

        public var summary: String {
            """
            Examples: \(totalExamples) (\(duplicateCount) duplicates)
            Balance: \(formatBalance())
            Banks: \(bankCoverage.keys.sorted().joined(separator: ", "))
            Sources: \(sourceCoverage.keys.sorted().joined(separator: ", "))
            """
        }

        private func formatBalance() -> String {
            balance
                .map { "\($0.key) \(String(format: "%.1f", $0.value * 100))%" }
                .joined(separator: ", ")
        }
    }

    public func validate(_ dataset: LabeledNarrationCollection) -> ValidationReport {
        var issues: [ValidationIssue] = []
        var warnings: [ValidationWarning] = []

        // Check minimum size
        if dataset.examples.isEmpty {
            issues.append(ValidationIssue(
                code: "EMPTY_DATASET",
                message: "Dataset contains zero examples"
            ))
        }

        if dataset.examples.count < 500 {
            warnings.append(ValidationWarning(
                code: "SMALL_DATASET",
                message: "Dataset has <500 examples (target: 5,000+)"
            ))
        }

        // Check balance
        warnings.append(contentsOf: checkBalance(dataset))

        // Check coverage
        if dataset.metadata.bankCoverage.count < 2 {
            warnings.append(ValidationWarning(
                code: "LIMITED_BANK_COVERAGE",
                message: "Only \(dataset.metadata.bankCoverage.count) banks represented (target: 5+)"
            ))
        }

        // Check for PII
        issues.append(contentsOf: checkForPII(dataset))

        // Check duplicates
        let narrations = Set(dataset.examples.map { $0.narration })
        let duplicateCount = dataset.examples.count - narrations.count
        if duplicateCount > 0 {
            warnings.append(ValidationWarning(
                code: "DUPLICATE_EXAMPLES",
                message: "\(duplicateCount) duplicate narrations found"
            ))
        }

        // Build metrics
        let metrics = ValidationMetrics(
            totalExamples: dataset.examples.count,
            uniqueExamples: narrations.count,
            duplicateCount: duplicateCount,
            balance: dataset.metadata.balance,
            bankCoverage: dataset.metadata.bankCoverage,
            sourceCoverage: dataset.metadata.sourceCoverage
        )

        return ValidationReport(
            isValid: issues.isEmpty,
            issues: issues,
            warnings: warnings,
            metrics: metrics
        )
    }

    // MARK: - Private

    private func checkBalance(_ dataset: LabeledNarrationCollection) -> [ValidationWarning] {
        var warnings: [ValidationWarning] = []
        let balance = dataset.metadata.balance
        let minRatio = 0.05
        for (label, ratio) in balance {
            if ratio > 0 && ratio < minRatio && dataset.examples.count > 100 {
                warnings.append(ValidationWarning(
                    code: "IMBALANCED_CLASS",
                    message: "Class '\(label)' has only \(String(format: "%.1f", ratio * 100))% of examples"
                ))
            }
        }
        return warnings
    }

    private func checkForPII(_ dataset: LabeledNarrationCollection) -> [ValidationIssue] {
        var issues: [ValidationIssue] = []
        for example in dataset.examples {
            if example.narration.contains(where: { $0.isNumber }) && example.narration.count < 20 {
                if example.narration.filter(\.isNumber).count >= 10 {
                    issues.append(ValidationIssue(
                        code: "POSSIBLE_PII_LEAK",
                        message: "Example '\(example.narration.prefix(50))' looks like unmasked phone number"
                    ))
                }
            }
        }
        return issues
    }

    /// Quick quality check for dataset before export.
    public func quickCheck(_ dataset: LabeledNarrationCollection) -> Bool {
        !validate(dataset).issues.isEmpty == false
    }
}

/// Evaluation helper for classifier performance.
public struct ClassifierEvaluator {
    public struct EvaluationMetrics: Codable, Sendable {
        public let accuracy: Double
        public let precision: [String: Double]
        public let recall: [String: Double]
        public let f1: [String: Double]

        public var summary: String {
            """
            Accuracy: \(String(format: "%.3f", accuracy))

            Per-class metrics:
            \(["person", "merchant", "unknown"].map { label in
                "  \(label):"
                    + " precision=\(String(format: "%.3f", precision[label] ?? 0))"
                    + " recall=\(String(format: "%.3f", recall[label] ?? 0))"
                    + " f1=\(String(format: "%.3f", f1[label] ?? 0))"
            }.joined(separator: "\n"))
            """
        }
    }

    /// Evaluate classifier predictions against labeled dataset.
    public func evaluate(
        classifier: PersonMerchantClassifier,
        against dataset: LabeledNarrationCollection
    ) -> EvaluationMetrics {
        let predictions = dataset.examples.map { example in
            (
                expected: example.label.rawValue,
                predicted: classifier.classify(example.narration).label.rawValue
            )
        }

        let correct = predictions.filter { $0.expected == $0.predicted }.count
        let accuracy = Double(correct) / Double(predictions.count)

        var tp: [String: Int] = [:]
        var fp: [String: Int] = [:]
        var fn: [String: Int] = [:]

        for (expected, predicted) in predictions {
            tp[expected, default: 0] += (expected == predicted) ? 1 : 0
            if expected != predicted {
                fp[predicted, default: 0] += 1
                fn[expected, default: 0] += 1
            }
        }

        var precision: [String: Double] = [:]
        var recall: [String: Double] = [:]
        var f1: [String: Double] = [:]

        for label in ["person", "merchant", "unknown"] {
            let tpCount = Double(tp[label] ?? 0)
            let fpCount = Double(fp[label] ?? 0)
            let fnCount = Double(fn[label] ?? 0)

            precision[label] = (tpCount + fpCount) > 0 ? tpCount / (tpCount + fpCount) : 0
            recall[label] = (tpCount + fnCount) > 0 ? tpCount / (tpCount + fnCount) : 0

            let p = precision[label] ?? 0
            let r = recall[label] ?? 0
            f1[label] = (p + r) > 0 ? 2 * (p * r) / (p + r) : 0
        }

        return EvaluationMetrics(accuracy: accuracy, precision: precision, recall: recall, f1: f1)
    }
}

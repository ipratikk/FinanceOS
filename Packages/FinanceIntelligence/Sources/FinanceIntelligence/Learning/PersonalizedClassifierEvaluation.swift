import Foundation

// MARK: - Stratified Evaluation (extension keeps actor body under type_body_length limit)

extension PersonalizedClassifier {
    // MARK: - Stratified Split

    /// Splits `examples` into disjoint train and validation sets using stratified sampling.
    ///
    /// - Categories with fewer than `minExamplesForSplit` examples are kept entirely in training
    ///   and recorded in `skippedCategories`.
    /// - For eligible categories: at least `minValidationPerClass` examples go to validation,
    ///   capped so at least one example remains in training.
    /// - Splits are deterministic: examples are sorted by text before partitioning.
    static func stratifiedSplit(
        examples: [(text: String, categoryId: String)],
        validationFraction: Double = 0.20,
        minValidationPerClass: Int = 1,
        minExamplesForSplit: Int = 5
    ) -> TrainValidationSplit {
        var byCategory: [String: [(text: String, categoryId: String)]] = [:]
        for example in examples {
            byCategory[example.categoryId, default: []].append(example)
        }
        var trainSet: [(text: String, categoryId: String)] = []
        var validationSet: [(text: String, categoryId: String)] = []
        var skippedCategories = Set<String>()
        for (category, categoryExamples) in byCategory {
            guard categoryExamples.count >= minExamplesForSplit else {
                trainSet.append(contentsOf: categoryExamples)
                skippedCategories.insert(category)
                continue
            }
            let sorted = categoryExamples.sorted { $0.text < $1.text }
            let desired = max(minValidationPerClass, Int(Double(sorted.count) * validationFraction))
            let valCount = min(desired, sorted.count - 1)
            validationSet.append(contentsOf: sorted.suffix(valCount))
            trainSet.append(contentsOf: sorted.dropLast(valCount))
        }
        return TrainValidationSplit(train: trainSet, validation: validationSet, skippedCategories: skippedCategories)
    }

    // MARK: - Held-Out Validation

    /// Evaluates the model on a held-out validation set derived from `examples` via `stratifiedSplit`.
    ///
    /// Training-set accuracy is never included. Check `hasReliableMetrics` before displaying
    /// numeric accuracy — when the validation set is too small, show "Insufficient validation data".
    func validateOnHeldOut(
        examples: [(text: String, categoryId: String)],
        validationFraction: Double = 0.20
    ) -> ClassificationEvaluationResult {
        let split = Self.stratifiedSplit(examples: examples, validationFraction: validationFraction)
        let distribution = Dictionary(grouping: examples, by: \.categoryId).mapValues(\.count)
        return computeMetrics(
            validationSet: split.validation, totalExamples: examples.count, distribution: distribution
        )
    }

    // MARK: - Private Metrics Computation

    private struct ValidationStats {
        var correct: Int = 0
        var totalConf: Double = 0
        var confidentCount: Int = 0
        var matrix: [String: [String: Int]] = [:]
        var truePositives: [String: Int] = [:]
        var falsePositives: [String: Int] = [:]
        var falseNegatives: [String: Int] = [:]
    }

    private func runPredictions(on validationSet: [(text: String, categoryId: String)]) -> ValidationStats {
        var stats = ValidationStats()
        for example in validationSet {
            let key = example.text.lowercased()
            guard let (predicted, confidence) = predict(normalizedDescription: key) else { continue }
            stats.matrix[example.categoryId, default: [:]][predicted, default: 0] += 1
            stats.confidentCount += 1
            stats.totalConf += confidence
            if predicted == example.categoryId {
                stats.correct += 1
                stats.truePositives[predicted, default: 0] += 1
            } else {
                stats.falsePositives[predicted, default: 0] += 1
                stats.falseNegatives[example.categoryId, default: 0] += 1
            }
        }
        return stats
    }

    private struct MacroAverages {
        let precision: Double
        let recall: Double
        let f1: Double
    }

    private func macroAverages(stats: ValidationStats, labels: Set<String>) -> MacroAverages {
        var precisions: [Double] = []
        var recalls: [Double] = []
        for label in labels {
            let tp = Double(stats.truePositives[label] ?? 0)
            let fp = Double(stats.falsePositives[label] ?? 0)
            let fn = Double(stats.falseNegatives[label] ?? 0)
            precisions.append(tp + fp > 0 ? tp / (tp + fp) : 0)
            recalls.append(tp + fn > 0 ? tp / (tp + fn) : 0)
        }
        let p = precisions.isEmpty ? 0 : precisions.reduce(0, +) / Double(precisions.count)
        let r = recalls.isEmpty ? 0 : recalls.reduce(0, +) / Double(recalls.count)
        return MacroAverages(precision: p, recall: r, f1: p + r > 0 ? 2 * p * r / (p + r) : 0)
    }

    private func computeMetrics(
        validationSet: [(text: String, categoryId: String)],
        totalExamples: Int,
        distribution: [String: Int]
    ) -> ClassificationEvaluationResult {
        guard !validationSet.isEmpty else {
            return ClassificationEvaluationResult(
                exampleCount: totalExamples, validationCount: 0, accuracy: 0,
                precisionMacro: 0, recallMacro: 0, f1Macro: 0,
                confusionMatrix: [:], coverage: 0, averageConfidence: nil,
                categoryDistribution: distribution
            )
        }
        let stats = runPredictions(on: validationSet)
        let allLabels = Set(validationSet.map(\.categoryId))
        let averages = macroAverages(stats: stats, labels: allLabels)
        let accuracy = stats.confidentCount > 0 ? Double(stats.correct) / Double(stats.confidentCount) : 0
        let uniqueCategories = Set(distribution.keys)
        let coverage = uniqueCategories.isEmpty ? 0 : Double(allLabels.count) / Double(uniqueCategories.count)
        let avgConf = stats.confidentCount > 0 ? stats.totalConf / Double(stats.confidentCount) : nil
        return ClassificationEvaluationResult(
            exampleCount: totalExamples,
            validationCount: validationSet.count,
            accuracy: accuracy,
            precisionMacro: averages.precision,
            recallMacro: averages.recall,
            f1Macro: averages.f1,
            confusionMatrix: stats.matrix,
            coverage: coverage,
            averageConfidence: avgConf,
            categoryDistribution: distribution
        )
    }
}

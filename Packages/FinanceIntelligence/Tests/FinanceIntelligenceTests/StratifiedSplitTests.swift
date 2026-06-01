@testable import FinanceIntelligence
import Testing

@Suite("PersonalizedClassifier.stratifiedSplit — held-out evaluation")
struct StratifiedSplitTests {
    // MARK: - Split Disjointness

    @Test("Split produces disjoint train and validation sets")
    func splitSetsAreDisjoint() {
        let examples = makeExamples(perCategory: 10, categories: ["dining", "groceries", "transfers"])
        let split = PersonalizedClassifier.stratifiedSplit(examples: examples)
        let trainTexts = Set(split.train.map(\.text))
        let valTexts = Set(split.validation.map(\.text))
        #expect(trainTexts.isDisjoint(with: valTexts))
    }

    @Test("Train + validation count equals total example count")
    func splitCoversTotalExamples() {
        let examples = makeExamples(perCategory: 8, categories: ["dining", "groceries"])
        let split = PersonalizedClassifier.stratifiedSplit(examples: examples)
        #expect(split.train.count + split.validation.count == examples.count)
    }

    // MARK: - Minimum Class Handling

    @Test("Categories with fewer than 5 examples go entirely to training")
    func smallCategoriesSkippedForValidation() {
        let small = makeExamples(perCategory: 3, categories: ["rare-category"])
        let large = makeExamples(perCategory: 10, categories: ["dining"])
        let split = PersonalizedClassifier.stratifiedSplit(examples: small + large)
        #expect(split.skippedCategories.contains("rare-category"))
        let valCategories = Set(split.validation.map(\.categoryId))
        #expect(!valCategories.contains("rare-category"))
    }

    @Test("Eligible categories appear in both train and validation")
    func eligibleCategoriesSplitAcrossSets() {
        let examples = makeExamples(perCategory: 10, categories: ["dining", "groceries"])
        let split = PersonalizedClassifier.stratifiedSplit(examples: examples)
        let trainCats = Set(split.train.map(\.categoryId))
        let valCats = Set(split.validation.map(\.categoryId))
        #expect(trainCats.contains("dining"))
        #expect(valCats.contains("dining"))
        #expect(trainCats.contains("groceries"))
        #expect(valCats.contains("groceries"))
    }

    // MARK: - Validation Fraction

    @Test("Validation set is approximately 20% of eligible examples")
    func validationFractionIsApproxTwentyPercent() {
        let examples = makeExamples(perCategory: 20, categories: ["dining", "groceries", "transfers"])
        let split = PersonalizedClassifier.stratifiedSplit(examples: examples, validationFraction: 0.20)
        let eligibleCount = examples.count
        let fraction = Double(split.validation.count) / Double(eligibleCount)
        #expect(fraction >= 0.15 && fraction <= 0.30)
    }

    // MARK: - Empty Input

    @Test("Empty examples produce empty split")
    func emptyInputProducesEmptySplit() {
        let split = PersonalizedClassifier.stratifiedSplit(examples: [])
        #expect(split.train.isEmpty)
        #expect(split.validation.isEmpty)
        #expect(split.skippedCategories.isEmpty)
    }

    // MARK: - Determinism

    @Test("Split is deterministic across multiple calls")
    func splitIsDeterministic() {
        let examples = makeExamples(perCategory: 10, categories: ["dining", "groceries"])
        let split1 = PersonalizedClassifier.stratifiedSplit(examples: examples)
        let split2 = PersonalizedClassifier.stratifiedSplit(examples: examples)
        #expect(split1.train.map(\.text) == split2.train.map(\.text))
        #expect(split1.validation.map(\.text) == split2.validation.map(\.text))
    }

    // MARK: - ClassificationEvaluationResult

    @Test("hasReliableMetrics is false for fewer than 10 validation examples")
    func insufficientValidationDataFlaggedCorrectly() {
        let result = ClassificationEvaluationResult(
            exampleCount: 5,
            validationCount: 3,
            accuracy: 0.5,
            precisionMacro: 0.5,
            recallMacro: 0.5,
            f1Macro: 0.5,
            confusionMatrix: [:],
            coverage: 0.5,
            averageConfidence: nil,
            categoryDistribution: [:]
        )
        #expect(!result.hasReliableMetrics)
    }

    @Test("hasReliableMetrics is true for 10 or more validation examples")
    func sufficientValidationDataFlaggedCorrectly() {
        let result = ClassificationEvaluationResult(
            exampleCount: 50,
            validationCount: 10,
            accuracy: 0.9,
            precisionMacro: 0.88,
            recallMacro: 0.87,
            f1Macro: 0.875,
            confusionMatrix: [:],
            coverage: 1.0,
            averageConfidence: 0.85,
            categoryDistribution: [:]
        )
        #expect(result.hasReliableMetrics)
    }

    // MARK: - Helpers

    private func makeExamples(
        perCategory: Int,
        categories: [String]
    ) -> [(text: String, categoryId: String)] {
        categories.flatMap { category in
            (0 ..< perCategory).map { i in (text: "\(category)-example-\(i)", categoryId: category) }
        }
    }
}

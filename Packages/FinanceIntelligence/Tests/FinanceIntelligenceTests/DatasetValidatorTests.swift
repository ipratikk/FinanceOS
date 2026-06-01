@testable import FinanceIntelligence
import Foundation
import Testing

@Test
func datasetValidator_validDataset() async {
    let collector = DatasetCollector()

    await collector.addFromFixture(
        narration: "UPI-JOHN-9876543210@upi-REF",
        label: .person,
        bank: "HDFC",
        direction: .debit
    )

    await collector.addFromFixture(
        narration: "UPI-AMAZON-amazonpay@razorpay-REF",
        label: .merchant,
        bank: "HDFC",
        direction: .debit
    )

    let dataset = await collector.buildDataset()
    let validator = DatasetValidator()
    let report = validator.validate(dataset)

    #expect(report.isValid)
    #expect(report.issues.isEmpty)
}

@Test
func datasetValidator_emptyDataset() {
    let collection = LabeledNarrationCollection(examples: [])
    let validator = DatasetValidator()
    let report = validator.validate(collection)

    #expect(!report.isValid)
    #expect(!report.issues.isEmpty)
    #expect(report.issues[0].code == "EMPTY_DATASET")
}

@Test
func datasetValidator_smallDataset_warning() async {
    let collector = DatasetCollector()

    for i in 0 ..< 100 {
        await collector.addFromFixture(
            narration: "Narration \(i)",
            label: .unknown,
            bank: "HDFC",
            direction: .debit
        )
    }

    let dataset = await collector.buildDataset()
    let validator = DatasetValidator()
    let report = validator.validate(dataset)

    #expect(report.isValid) // no issues, just warnings
    #expect(!report.warnings.isEmpty)
    let hasSmallDatasetWarning = report.warnings.contains { $0.code == "SMALL_DATASET" }
    #expect(hasSmallDatasetWarning)
}

@Test
func classifierEvaluator_perfectClassifier() async {
    let collector = DatasetCollector()

    await collector.addFromFixture(
        narration: "UPI-JOHN-9876543210@upi-REF",
        label: .person,
        bank: "HDFC",
        direction: .debit
    )

    await collector.addFromFixture(
        narration: "UPI-AMAZON-amazonpay@razorpay-REF",
        label: .merchant,
        bank: "HDFC",
        direction: .debit
    )

    let dataset = await collector.buildDataset()
    let classifier = PersonMerchantClassifier()
    let evaluator = ClassifierEvaluator()
    let metrics = evaluator.evaluate(classifier: classifier, against: dataset)

    #expect(metrics.accuracy == 1.0) // perfect on these examples
}

@Test
func classifierEvaluator_metrics_summary() async {
    let collector = DatasetCollector()

    // Build test dataset
    await collector.addFromFixture(
        narration: "UPI-JOHN-9876543210@upi-REF1",
        label: .person,
        bank: "HDFC",
        direction: .debit
    )

    await collector.addFromFixture(
        narration: "UPI-AMAZON-amazonpay@razorpay-REF2",
        label: .merchant,
        bank: "HDFC",
        direction: .debit
    )

    let dataset = await collector.buildDataset()
    let classifier = PersonMerchantClassifier()
    let evaluator = ClassifierEvaluator()
    let metrics = evaluator.evaluate(classifier: classifier, against: dataset)

    // Just verify the summary is generated
    #expect(!metrics.summary.isEmpty)
    #expect(metrics.summary.contains("Accuracy"))
}

@testable import FinanceIntelligence
import Foundation
import Testing

@Test
func datasetCollector_addFromFixture() async {
    let collector = DatasetCollector(annotationGuidelines: "Test guidelines")

    await collector.addFromFixture(
        narration: "UPI-JOHN DOE-9876543210@upi-HDFC0-REF123",
        label: .person,
        bank: "HDFC",
        direction: .debit,
        amountMinorUnits: 10000
    )

    let dataset = await collector.buildDataset()
    #expect(dataset.examples.count == 1)
    #expect(dataset.examples[0].label == .person)
    #expect(dataset.metadata.totalCount == 1)
    #expect(dataset.metadata.personCount == 1)
}

@Test
func datasetCollector_multipleExamples() async {
    let collector = DatasetCollector()

    await collector.addFromFixture(
        narration: "UPI-SWIGGY-swiggy@swiggypay-HDFC0-REF1",
        label: .merchant,
        bank: "HDFC",
        direction: .debit
    )

    await collector.addFromFixture(
        narration: "UPI-RAJESH-9123456789@upi-ICIC0-REF2",
        label: .person,
        bank: "ICICI",
        direction: .debit
    )

    await collector.addFromFixture(
        narration: "NEFT-DR-ABCD-UNKNOWN PARTY-REF3",
        label: .unknown,
        bank: "AXIS",
        direction: .debit
    )

    let dataset = await collector.buildDataset()
    #expect(dataset.metadata.totalCount == 3)
    #expect(dataset.metadata.merchantCount == 1)
    #expect(dataset.metadata.personCount == 1)
    #expect(dataset.metadata.unknownCount == 1)
    #expect(dataset.metadata.bankCoverage["HDFC"] == 1)
    #expect(dataset.metadata.bankCoverage["ICICI"] == 1)
    #expect(dataset.metadata.bankCoverage["AXIS"] == 1)
}

@Test
func datasetCollection_csvExport() async {
    let collector = DatasetCollector()

    await collector.addFromFixture(
        narration: "Test Narration 1",
        label: .person,
        bank: "HDFC",
        direction: .debit
    )

    await collector.addFromFixture(
        narration: "Test, Narration, 2",
        label: .merchant,
        bank: "ICICI",
        direction: .credit
    )

    let csv = await collector.exportCSV()
    #expect(csv.contains("narration,label,bank,source,direction,vpa"))
    #expect(csv.contains("Test Narration 1,person,HDFC,parser_fixture,debit"))
    #expect(csv.contains("\"Test, Narration, 2\",merchant,ICICI,parser_fixture,credit"))
}

@Test
func datasetCollection_jsonExport() async throws {
    let collector = DatasetCollector()

    await collector.addFromFixture(
        narration: "Example narration",
        label: .person,
        bank: "HDFC",
        direction: .debit
    )

    let jsonData = try await collector.exportJSON()
    let collection = try JSONDecoder().decode(LabeledNarrationCollection.self, from: jsonData)
    #expect(collection.examples.count == 1)
    #expect(collection.examples[0].label == .person)
}

@Test
func datasetCollection_statistics() async {
    let collector = DatasetCollector()

    for i in 0 ..< 10 {
        let label: LabeledNarration.NarrationLabel = i % 2 == 0 ? .person : .merchant
        await collector.addFromFixture(
            narration: "Example \(i)",
            label: label,
            bank: "HDFC",
            direction: .debit
        )
    }

    let stats = await collector.statistics()
    #expect(stats.totalCount == 10)
    #expect(stats.personCount == 5)
    #expect(stats.merchantCount == 5)
    #expect(stats.unknownCount == 0)
}

@Test
func fixtureNarrationExtractor_csvParsing() {
    let csv = """
    Date,Narration,Amount
    01/04/26,UPI-JOHN DOE-9876543210@upi,500.00
    02/04/26,UPI-AMAZON-amazonpay@razorpay,2000.00
    03/04/26,NEFT-UNKNOWN,1000.00
    """

    let extracted = FixtureNarrationExtractor.extractFromCSV(
        content: csv,
        bank: "HDFC",
        narrationColumnIndex: 1
    )

    #expect(extracted.count == 3)
    #expect(extracted[0].narration == "UPI-JOHN DOE-9876543210@upi")
    #expect(extracted[0].suggestedLabel == "person")
    #expect(extracted[1].suggestedLabel == "merchant")
    #expect(extracted[2].suggestedLabel == "unknown")
}

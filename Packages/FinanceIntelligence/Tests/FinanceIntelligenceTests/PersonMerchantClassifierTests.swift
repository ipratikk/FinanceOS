@testable import FinanceIntelligence
import Foundation
import Testing

@Test
func personMerchantClassifier_phoneVPA_classfiesAsPerson() {
    let classifier = PersonMerchantClassifier()
    let narration = "UPI-JOHN DOE-9876543210@upi-HDFC0-REF"

    let pred = classifier.classify(narration)
    #expect(pred.label == .person)
    #expect(pred.confidence == .certain)
}

@Test
func personMerchantClassifier_merchantGateway_classifiesAsMerchant() {
    let classifier = PersonMerchantClassifier()
    let narration = "UPI-AMAZON-amazonpay@razorpay-REF"

    let pred = classifier.classify(narration)
    #expect(pred.label == .merchant)
    #expect(pred.confidence == .certain)
}

@Test
func personMerchantClassifier_businessKeyword_classifiesAsMerchant() {
    let classifier = PersonMerchantClassifier()
    let narration = "UPI-SWIGGY PRIVATE LIMITED-REF"

    let pred = classifier.classify(narration)
    #expect(pred.label == .merchant)
    #expect(pred.confidence >= .moderate)
}

@Test
func personMerchantClassifier_singleKeyword_lowerConfidence() {
    let classifier = PersonMerchantClassifier()
    let narration = "UPI-NETFLIX-REF"

    let pred = classifier.classify(narration)
    #expect(pred.label == .merchant)
    #expect(pred.confidence == .moderate) // single keyword = lower confidence
}

@Test
func personMerchantClassifier_personName_classifiesAsPerson() {
    let classifier = PersonMerchantClassifier()
    let narration = "NEFT CR-RAJESH SHARMA-REF"

    let pred = classifier.classify(narration)
    #expect(pred.label == .person)
}

@Test
func personMerchantClassifier_ambiguous_classifiesAsUnknown() {
    let classifier = PersonMerchantClassifier()
    let narration = "NEFT-UNKNOWN-REF"

    let pred = classifier.classify(narration)
    #expect(pred.label == .unknown)
    #expect(pred.confidence == .low)
}

@Test
func personMerchantClassifier_batchClassify() {
    let classifier = PersonMerchantClassifier()
    let narrations = [
        "UPI-JOHN-9876543210@upi-REF",
        "UPI-AMAZON-amazonpay@razorpay-REF",
        "NEFT-UNKNOWN-REF"
    ]

    let predictions = classifier.classify(narrations)
    #expect(predictions.count == 3)
    #expect(predictions[0].label == .person)
    #expect(predictions[1].label == .merchant)
    #expect(predictions[2].label == .unknown)
}

@Test
func personMerchantClassifier_confidenceScore() {
    let classifier = PersonMerchantClassifier()
    let narration = "UPI-JOHN-9876543210@upi-REF"

    let pred = classifier.classify(narration)
    let score = classifier.confidenceScore(pred)
    #expect(score == 0.95) // certain
}

@Test
func personMerchantClassifier_baselineAccuracy() {
    let classifier = PersonMerchantClassifier()

    let testCases: [(String, PersonMerchantClassifier.Label)] = [
        ("UPI-JOHN KUMAR-9876543210@upi-HDFC0-REF1", .person),
        ("UPI-RAJESH-9123456789@ybl-ICIC0-REF2", .person),
        ("NEFT CR-HDFC0-PRIYA PATEL-REF3", .person),
        ("UPI-SWIGGY-swiggy@swiggypay-HDFC0-REF6", .merchant),
        ("UPI-AMAZON-amazonpay@razorpay-ICIC0-REF7", .merchant),
        ("NEFT DR-ICIC0-NETFLIX INDIA PVT LTD-REF8", .merchant),
        ("NEFT-UNKNOWN-ABC123", .unknown),
        ("TRANSFER REFERENCE XYZ", .unknown)
    ]

    let predictions = testCases.map { classifier.classify($0.0) }
    let correct = zip(predictions, testCases).filter { $0.0.label == $0.1.1 }.count
    let accuracy = Double(correct) / Double(testCases.count)

    #expect(accuracy >= 0.75) // baseline should hit 75%+
}

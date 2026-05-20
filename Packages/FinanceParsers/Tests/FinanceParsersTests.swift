@testable import FinanceParsers
import Foundation
import Testing

@Test
func parserExists() {
    let parser = HDFCPDFParser()
    #expect(parser.supportedFormat == .pdf)
}
